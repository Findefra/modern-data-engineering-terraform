###############################################################################
# BigQuery Dataset Module
#
# Real-world notes:
# - Create separate datasets for raw (external), intermediate, and curated.
# - Prefer BigLake / external tables for large landing data when you don't
#   need full native performance yet.
# - Default table expiration is a good safety net in non-prod.
# - Labels + dataset access control matter more than most people think once
#   you have multiple teams.
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
    module      = "bigquery-dataset"
    environment = var.environment
    project     = var.project_name
  })
}

resource "google_bigquery_dataset" "raw" {
  dataset_id                 = "${var.project_name}_${var.environment}_raw"
  project                    = var.project_id
  location                   = var.location
  description                = "Raw / external landing dataset"
  delete_contents_on_destroy = var.delete_contents_on_destroy
  default_table_expiration_ms = var.default_table_expiration_ms

  labels = merge(local.common_labels, { layer = "raw" })
}

resource "google_bigquery_dataset" "processed" {
  dataset_id                 = "${var.project_name}_${var.environment}_processed"
  project                    = var.project_id
  location                   = var.location
  description                = "Cleaned / standardized dataset"
  delete_contents_on_destroy = var.delete_contents_on_destroy
  default_table_expiration_ms = var.default_table_expiration_ms

  labels = merge(local.common_labels, { layer = "processed" })
}

resource "google_bigquery_dataset" "curated" {
  dataset_id                 = "${var.project_name}_${var.environment}_curated"
  project                    = var.project_id
  location                   = var.location
  description                = "Business-ready curated dataset"
  delete_contents_on_destroy = var.delete_contents_on_destroy

  labels = merge(local.common_labels, { layer = "curated" })
}
