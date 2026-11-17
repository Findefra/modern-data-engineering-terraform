variable "enable_composer" {
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

variable "composer_image_version" {
  description = "Composer image version. Pin deliberately."
  type        = string
  default     = "composer-2.9.7-airflow-2.9.3"
}

variable "service_account_email" {
  type = string
}

variable "network" {
  type    = string
  default = null
}

variable "subnetwork" {
  type    = string
  default = null
}

variable "labels" {
  type    = map(string)
  default = {}
}
