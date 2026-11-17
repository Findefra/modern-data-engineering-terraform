variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "force_destroy" {
  type    = bool
  default = false
}

variable "enable_redshift" {
  type    = bool
  default = false
}

variable "redshift_admin_password" {
  type      = string
  sensitive = true
  default   = null
}

variable "redshift_base_rpu" {
  type    = number
  default = 8
}

variable "private_subnet_ids" {
  type    = list(string)
  default = []
}

variable "redshift_security_group_ids" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
