variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "lake_bucket_arns" {
  description = "List of S3 bucket ARNs the Glue role needs access to"
  type        = list(string)
}

variable "raw_bucket_id" {
  type = string
}

variable "cleaned_bucket_id" {
  type = string
}

variable "scripts_bucket_arn" {
  description = "Optional bucket ARN where Glue scripts live"
  type        = string
  default     = null
}

variable "create_raw_crawler" {
  type    = bool
  default = true
}

variable "create_example_job" {
  type    = bool
  default = false
}

variable "example_script_location" {
  description = "s3:// path to the example Glue script"
  type        = string
  default     = null
}

variable "glue_worker_type" {
  type    = string
  default = "G.1X"
}

variable "glue_number_of_workers" {
  type    = number
  default = 2
}

variable "glue_timeout_minutes" {
  type    = number
  default = 60
}

variable "tags" {
  type    = map(string)
  default = {}
}
