variable "project_id" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "message_retention_duration" {
  type    = string
  default = "604800s" # 7 days
}

variable "subscription_retention_duration" {
  type    = string
  default = "604800s"
}

variable "ack_deadline_seconds" {
  type    = number
  default = 60
}

variable "max_delivery_attempts" {
  type    = number
  default = 5
}

variable "bigquery_table" {
  description = "project.dataset.table for native Pub/Sub → BigQuery. Null to disable."
  type        = string
  default     = null
}

variable "create_dataflow_streaming_job" {
  type    = bool
  default = false
}

variable "dataflow_template_gcs_path" {
  type    = string
  default = null
}

variable "dataflow_temp_gcs_location" {
  type    = string
  default = null
}

variable "dataflow_output_path" {
  type    = string
  default = null
}

variable "dataflow_max_workers" {
  type    = number
  default = 5
}

variable "dataflow_extra_parameters" {
  type    = map(string)
  default = {}
}

variable "service_account_email" {
  type    = string
  default = null
}

variable "labels" {
  type    = map(string)
  default = {}
}
