###############################################################################
# Dataflow Pipeline (Flex Template skeleton)
#
# Real-world notes:
# - Prefer Flex Templates over classic for new work.
# - Always set a service account with least privilege.
# - Temp and staging locations should be dedicated, short-lived prefixes.
# - Streaming vs batch has very different cost profiles — don't mix them
#   carelessly in the same job design.
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

resource "google_dataflow_job" "batch_example" {
  count = var.create_example_job ? 1 : 0

  name                    = "${var.project_name}-${var.environment}-batch-example"
  project                 = var.project_id
  region                  = var.region
  template_gcs_path       = var.template_gcs_path
  temp_gcs_location       = var.temp_gcs_location
  service_account_email   = var.service_account_email
  max_workers             = var.max_workers
  on_delete               = "cancel"
  enable_streaming_engine = false

  parameters = var.job_parameters

  labels = merge(var.labels, {
    environment = var.environment
    project     = var.project_name
  })
}
