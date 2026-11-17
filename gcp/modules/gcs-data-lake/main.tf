###############################################################################
# GCS Data Lake Module — Landing / Processed / Curated
#
# Real-world notes:
# - Soft delete + versioning on the landing bucket saves you from accidental
#   deletes more often than you expect.
# - Lifecycle rules are cheap insurance. Start aggressive on landing, more
#   conservative on curated.
# - Uniform bucket-level access is the modern default; avoid ACLs.
# - Separate buckets (or at least strict prefix + different IAM) still help
#   with cost attribution and blast radius.
###############################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

locals {
  common_labels = merge(var.labels, {
    module      = "gcs-data-lake"
    environment = var.environment
    project     = var.project_name
  })

  zones = {
    landing   = { name = "${var.project_name}-${var.environment}-landing", purpose = "immutable-landing" }
    processed = { name = "${var.project_name}-${var.environment}-processed", purpose = "cleaned-standardized" }
    curated   = { name = "${var.project_name}-${var.environment}-curated", purpose = "business-ready" }
  }
}

resource "google_storage_bucket" "zone" {
  for_each = local.zones

  name          = each.value.name
  project       = var.project_id
  location      = var.location
  storage_class = "STANDARD"
  force_destroy = var.force_destroy

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = var.enable_versioning
  }

  soft_delete_policy {
    retention_duration_seconds = var.soft_delete_retention_seconds
  }

  dynamic "lifecycle_rule" {
    for_each = each.key == "landing" ? [1] : []
    content {
      condition {
        age = var.landing_nearline_age_days
      }
      action {
        type          = "SetStorageClass"
        storage_class = "NEARLINE"
      }
    }
  }

  dynamic "lifecycle_rule" {
    for_each = each.key == "landing" ? [1] : []
    content {
      condition {
        age = var.landing_coldline_age_days
      }
      action {
        type          = "SetStorageClass"
        storage_class = "COLDLINE"
      }
    }
  }

  labels = merge(local.common_labels, {
    zone    = each.key
    purpose = each.value.purpose
  })
}
