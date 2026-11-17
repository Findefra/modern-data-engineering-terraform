variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "db_name" {
  type    = string
  default = "analytics"
}

variable "admin_username" {
  type    = string
  default = "rsadmin"
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "base_capacity_rpu" {
  description = "Base RPU capacity. Start conservative (8–32)."
  type        = number
  default     = 8
}

variable "max_capacity_rpu" {
  description = "Optional max RPU. Null = no hard cap (still subject to account limits)."
  type        = number
  default     = null
}

variable "subnet_ids" {
  description = "Private subnet IDs for the workgroup"
  type        = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "iam_role_arns" {
  description = "IAM roles to associate (e.g. for Spectrum / COPY)"
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
