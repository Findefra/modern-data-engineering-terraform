variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "glue_job_name" {
  description = "Name of the Glue job to run (must already exist)"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
