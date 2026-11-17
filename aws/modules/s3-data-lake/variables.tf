variable "project_name" {
  description = "Short project name used in resource naming (lowercase, no spaces)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "force_destroy" {
  description = "Allow Terraform to destroy non-empty buckets. Only true in non-prod."
  type        = bool
  default     = false
}

variable "enable_versioning" {
  description = "Enable versioning on all zone buckets. Strongly recommended for Raw."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Optional customer-managed KMS key ARN. Null = SSE-S3."
  type        = string
  default     = null
}

variable "enable_access_logging" {
  description = "Create a dedicated access logs bucket and enable logging on zones."
  type        = bool
  default     = true
}

# Lifecycle tunables — these values are starting points, not gospel.
# Review after real traffic.
variable "raw_transition_to_ia_days" {
  type    = number
  default = 30
}

variable "raw_transition_to_glacier_days" {
  type    = number
  default = 90
}

variable "raw_noncurrent_expiration_days" {
  type    = number
  default = 90
}

variable "cleaned_transition_to_ia_days" {
  type    = number
  default = 60
}

variable "curated_lifecycle_enabled" {
  type    = bool
  default = false
}

variable "curated_transition_to_ia_days" {
  type    = number
  default = 180
}

variable "tags" {
  description = "Additional tags applied to all resources"
  type        = map(string)
  default     = {}
}
