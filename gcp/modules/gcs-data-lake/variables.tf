variable "project_id" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type    = string
  default = "US"
}

variable "force_destroy" {
  type    = bool
  default = false
}

variable "enable_versioning" {
  type    = bool
  default = true
}

variable "soft_delete_retention_seconds" {
  description = "Soft delete retention (7 days default). Set 0 to disable if your org policy allows."
  type        = number
  default     = 604800
}

variable "landing_nearline_age_days" {
  type    = number
  default = 30
}

variable "landing_coldline_age_days" {
  type    = number
  default = 90
}

variable "labels" {
  type    = map(string)
  default = {}
}
