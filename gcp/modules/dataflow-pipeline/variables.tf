variable "create_example_job" {
  type    = bool
  default = false
}

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

variable "template_gcs_path" {
  type    = string
  default = null
}

variable "temp_gcs_location" {
  type    = string
  default = null
}

variable "service_account_email" {
  type = string
}

variable "max_workers" {
  type    = number
  default = 2
}

variable "job_parameters" {
  type    = map(string)
  default = {}
}

variable "labels" {
  type    = map(string)
  default = {}
}
