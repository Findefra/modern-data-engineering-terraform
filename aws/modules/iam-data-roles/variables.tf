variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "lake_bucket_arns" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
