###############################################################################
# S3 Data Lake Module — Medallion (Raw / Cleaned / Curated)
#
# Real-world notes:
# - Separate buckets give cleaner IAM, lifecycle, and cost attribution.
# - Many teams start with one bucket + prefixes and regret it when legal
#   retention, encryption keys, or cross-account access diverge.
# - Versioning + Object Lock (compliance mode) on Raw is often required
#   in regulated environments. Enable deliberately — it has cost.
# - Lifecycle rules are not "set and forget". Review after the first 3 months
#   of real data volume; the transition days you choose in week 1 are usually wrong.
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
    Module      = "s3-data-lake"
    Environment = var.environment
    Project     = var.project_name
  })

  zones = {
    raw     = { name = "${var.project_name}-${var.environment}-raw", purpose = "immutable-landing" }
    cleaned = { name = "${var.project_name}-${var.environment}-cleaned", purpose = "validated-standardized" }
    curated = { name = "${var.project_name}-${var.environment}-curated", purpose = "business-ready" }
  }
}

resource "aws_s3_bucket" "zone" {
  for_each = local.zones

  bucket        = each.value.name
  force_destroy = var.force_destroy

  tags = merge(local.common_tags, {
    Zone    = each.key
    Purpose = each.value.purpose
  })
}

resource "aws_s3_bucket_versioning" "zone" {
  for_each = aws_s3_bucket.zone

  bucket = each.value.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "zone" {
  for_each = aws_s3_bucket.zone

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = var.kms_key_arn != null
  }
}

resource "aws_s3_bucket_public_access_block" "zone" {
  for_each = aws_s3_bucket.zone

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle — aggressive on Raw, more conservative on Curated
resource "aws_s3_bucket_lifecycle_configuration" "raw" {
  bucket = aws_s3_bucket.zone["raw"].id

  rule {
    id     = "raw-transition"
    status = "Enabled"

    filter { prefix = "" }

    transition {
      days          = var.raw_transition_to_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.raw_transition_to_glacier_days
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.raw_noncurrent_expiration_days
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cleaned" {
  bucket = aws_s3_bucket.zone["cleaned"].id

  rule {
    id     = "cleaned-transition"
    status = "Enabled"

    filter { prefix = "" }

    transition {
      days          = var.cleaned_transition_to_ia_days
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "curated" {
  count  = var.curated_lifecycle_enabled ? 1 : 0
  bucket = aws_s3_bucket.zone["curated"].id

  rule {
    id     = "curated-transition"
    status = "Enabled"

    filter { prefix = "" }

    transition {
      days          = var.curated_transition_to_ia_days
      storage_class = "STANDARD_IA"
    }
  }
}

# Optional: logging bucket (highly recommended in production)
resource "aws_s3_bucket" "access_logs" {
  count         = var.enable_access_logging ? 1 : 0
  bucket        = "${var.project_name}-${var.environment}-s3-access-logs"
  force_destroy = var.force_destroy

  tags = merge(local.common_tags, { Purpose = "s3-access-logs" })
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  count  = var.enable_access_logging ? 1 : 0
  bucket = aws_s3_bucket.access_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "zone" {
  for_each = var.enable_access_logging ? aws_s3_bucket.zone : {}

  bucket = each.value.id

  target_bucket = aws_s3_bucket.access_logs[0].id
  target_prefix = "${each.key}/"
}
