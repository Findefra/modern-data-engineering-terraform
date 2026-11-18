variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "database_name" {
  description = "Glue catalog database that already exists"
  type        = string
}

variable "tables" {
  description = <<-EOT
    List of Iceberg table definitions.
    Example:
    [
      {
        name        = "orders_silver"
        location    = "s3://my-cleaned/orders/"
        description = "Cleaned orders"
        columns = [
          { name = "order_id", type = "string" },
          { name = "amount", type = "double" },
          { name = "order_ts", type = "timestamp" }
        ]
        partition_keys = [
          { name = "order_date", type = "date" }
        ]
      }
    ]
  EOT
  type = list(object({
    name             = string
    location         = string
    description      = optional(string)
    write_format     = optional(string)
    compression      = optional(string)
    extra_parameters = optional(map(string))
    columns = list(object({
      name    = string
      type    = string
      comment = optional(string)
    }))
    partition_keys = optional(list(object({
      name = string
      type = string
    })))
  }))
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
