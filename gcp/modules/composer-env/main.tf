###############################################################################
# Cloud Composer (optional)
#
# Real-world warning:
# Composer is powerful and expensive. Environment creation can take 20–40+
# minutes. Many teams over-commit to Composer early and then struggle with
# cost and upgrade pain.
#
# Prefer Cloud Workflows + Dataflow or Scheduler + Dataflow for simpler
# pipelines. Use Composer when you truly need Airflow features (complex
# dependencies, sensors, rich operators, multi-team DAG ownership).
#
# This module is a thin, opinionated starting point. For production, pin
# image versions carefully and use private IP + Shared VPC patterns.
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

resource "google_composer_environment" "this" {
  count   = var.enable_composer ? 1 : 0
  name    = "${var.project_name}-${var.environment}-composer"
  project = var.project_id
  region  = var.region

  config {
    software_config {
      image_version = var.composer_image_version
    }

    workloads_config {
      scheduler {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        count      = 1
      }
      web_server {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
      }
      worker {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        min_count  = 1
        max_count  = 3
      }
    }

    environment_size = "ENVIRONMENT_SIZE_SMALL"

    node_config {
      service_account = var.service_account_email
      network         = var.network
      subnetwork      = var.subnetwork
    }
  }

  labels = merge(var.labels, {
    environment = var.environment
    project     = var.project_name
  })
}
