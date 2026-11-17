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

variable "delete_contents_on_destroy" {
  type    = bool
  default = false
}

variable "default_table_expiration_ms" {
  description = "Optional default expiration for tables in non-prod datasets (null = never)"
  type        = number
  default     = null
}

variable "labels" {
  type    = map(string)
  default = {}
}
