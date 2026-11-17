###############################################################################
# Glue Catalog + ETL Module
#
# Real-world notes:
# - One Glue Database per domain or per environment is usually cleaner than
#   a single giant database.
# - Crawlers are convenient for discovery; they are not a substitute for
#   explicit schema management once you care about stability.
# - Prefer writing Iceberg tables from jobs rather than relying on crawlers
#   for production tables.
# - Job bookmarks are great until they aren't. Test re-processing paths.
# - Always set a max concurrent runs and a timeout. Runaway jobs are expensive.
###############################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  common_tags = merge(var.tags, {
    Module      = "glue-catalog-etl"
    Environment = var.environment
    Project     = var.project_name
  })
}

# ---------------------------------------------------------------------------
# Glue Database (Catalog)
# ---------------------------------------------------------------------------
resource "aws_glue_catalog_database" "this" {
  name = "${var.project_name}_${var.environment}_db"

  description = "Catalog database for ${var.project_name} ${var.environment}"

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# IAM Role for Glue jobs / crawlers
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "glue_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "glue" {
  name               = "${var.project_name}-${var.environment}-glue-role"
  assume_role_policy = data.aws_iam_policy_document.glue_assume.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Tight S3 access — only the lake buckets + optional scripts bucket
data "aws_iam_policy_document" "glue_s3" {
  statement {
    sid    = "ListBuckets"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = var.lake_bucket_arns
  }

  statement {
    sid    = "ObjectAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [for arn in var.lake_bucket_arns : "${arn}/*"]
  }

  dynamic "statement" {
    for_each = var.scripts_bucket_arn != null ? [1] : []
    content {
      sid       = "ScriptsAccess"
      effect    = "Allow"
      actions   = ["s3:GetObject", "s3:PutObject"]
      resources = ["${var.scripts_bucket_arn}/*"]
    }
  }
}

resource "aws_iam_role_policy" "glue_s3" {
  name   = "glue-s3-access"
  role   = aws_iam_role.glue.id
  policy = data.aws_iam_policy_document.glue_s3.json
}

# CloudWatch Logs
resource "aws_iam_role_policy_attachment" "glue_logs" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess" # tighten in real prod
}

# ---------------------------------------------------------------------------
# Optional Crawler for Raw zone discovery
# ---------------------------------------------------------------------------
resource "aws_glue_crawler" "raw" {
  count = var.create_raw_crawler ? 1 : 0

  name          = "${var.project_name}-${var.environment}-raw-crawler"
  role          = aws_iam_role.glue.arn
  database_name = aws_glue_catalog_database.this.name

  s3_target {
    path = "s3://${var.raw_bucket_id}/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
  })

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Sample Glue Job (PySpark) — template for real jobs
# ---------------------------------------------------------------------------
resource "aws_glue_job" "etl_example" {
  count = var.create_example_job ? 1 : 0

  name     = "${var.project_name}-${var.environment}-etl-example"
  role_arn = aws_iam_role.glue.arn

  glue_version      = "4.0"
  worker_type       = var.glue_worker_type
  number_of_workers = var.glue_number_of_workers
  timeout           = var.glue_timeout_minutes
  max_retries       = 1

  execution_property {
    max_concurrent_runs = 1
  }

  command {
    name            = "glueetl"
    script_location = var.example_script_location
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-job-insights"              = "true"
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--TempDir"                          = "s3://${var.raw_bucket_id}/_glue_temp/"
    "--raw_path"                         = "s3://${var.raw_bucket_id}/"
    "--cleaned_path"                     = "s3://${var.cleaned_bucket_id}/"
  }

  tags = local.common_tags
}
