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
  type    = string
  default = "us-central1"
}

variable "location" {
  type    = string
  default = "US"
}

variable "force_destroy" {
  type    = bool
  default = false
}

variable "enable_composer" {
  type    = bool
  default = false
}

variable "labels" {
  type    = map(string)
  default = {}
}
