###############################################################################
# IAM Data Roles Module
#
# Keeps role creation out of the other modules so you can share roles or
# apply different policies without forking the storage/ETL modules.
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
    Module      = "iam-data-roles"
    Environment = var.environment
    Project     = var.project_name
  })
}

# Role that Redshift / Athena can use to read the lake
data "aws_iam_policy_document" "redshift_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["redshift.amazonaws.com", "redshift-serverless.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "redshift_spectrum" {
  name               = "${var.project_name}-${var.environment}-redshift-spectrum"
  assume_role_policy = data.aws_iam_policy_document.redshift_assume.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "spectrum_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = concat(var.lake_bucket_arns, [for a in var.lake_bucket_arns : "${a}/*"])
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetTable",
      "glue:GetPartitions",
      "glue:GetDatabases",
      "glue:GetTables"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "spectrum_s3" {
  name   = "spectrum-s3-glue"
  role   = aws_iam_role.redshift_spectrum.id
  policy = data.aws_iam_policy_document.spectrum_s3.json
}
