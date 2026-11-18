###############################################################################
# Pub/Sub + optional Dataflow streaming landing
#
# Real-world notes:
# - Pub/Sub is the ingestion bus; BigQuery or GCS is the landing. Don't treat
#   Pub/Sub as long-term storage.
# - Subscriptions with dead-letter topics are non-negotiable in production.
#   Without them, poison messages block consumers.
# - Dataflow streaming jobs are long-lived. Cost profile is very different
#   from batch. Use autoscaling and set a sensible max workers.
# - Prefer subscription push to BigQuery (native) when schema is stable and
#   you don't need heavy transforms. Use Dataflow when you need Beam logic.
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
    module      = "pubsub-streaming"
    environment = var.environment
    project     = var.project_name
  })
  topic_name        = "${var.project_name}-${var.environment}-events"
  subscription_name = "${var.project_name}-${var.environment}-events-sub"
  dlq_topic_name    = "${var.project_name}-${var.environment}-events-dlq"
}

resource "google_pubsub_topic" "events" {
  name    = local.topic_name
  project = var.project_id

  message_retention_duration = var.message_retention_duration
  labels                     = local.common_labels
}

resource "google_pubsub_topic" "dlq" {
  name    = local.dlq_topic_name
  project = var.project_id
  labels  = local.common_labels
}

resource "google_pubsub_subscription" "events" {
  name    = local.subscription_name
  project = var.project_id
  topic   = google_pubsub_topic.events.name

  ack_deadline_seconds       = var.ack_deadline_seconds
  message_retention_duration = var.subscription_retention_duration
  retain_acked_messages      = false

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dlq.id
    max_delivery_attempts = var.max_delivery_attempts
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  dynamic "bigquery_config" {
    for_each = var.bigquery_table != null ? [1] : []
    content {
      table               = var.bigquery_table
      write_metadata      = true
      drop_unknown_fields = true
    }
  }

  labels = local.common_labels
}

resource "google_dataflow_job" "streaming" {
  count = var.create_dataflow_streaming_job ? 1 : 0

  name                    = "${var.project_name}-${var.environment}-stream"
  project                 = var.project_id
  region                  = var.region
  template_gcs_path       = var.dataflow_template_gcs_path
  temp_gcs_location       = var.dataflow_temp_gcs_location
  service_account_email   = var.service_account_email
  max_workers             = var.dataflow_max_workers
  on_delete               = "cancel"
  enable_streaming_engine = true

  parameters = merge(
    {
      inputSubscription = google_pubsub_subscription.events.id
      outputPath        = var.dataflow_output_path
    },
    var.dataflow_extra_parameters
  )

  labels = local.common_labels
}
