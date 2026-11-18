variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "destination_bucket_arn" {
  description = "S3 bucket ARN for Firehose delivery (typically the Raw zone)"
  type        = string
}

variable "create_kinesis_stream" {
  description = "If true, create a Kinesis Data Stream and use it as Firehose source. If false, Firehose is Direct PUT."
  type        = bool
  default     = false
}

variable "stream_mode" {
  description = "PROVISIONED or ON_DEMAND"
  type        = string
  default     = "ON_DEMAND"
}

variable "shard_count" {
  description = "Only used when stream_mode = PROVISIONED"
  type        = number
  default     = 1
}

variable "retention_hours" {
  type    = number
  default = 24
}

variable "kms_key_id" {
  type    = string
  default = null
}

variable "s3_prefix" {
  description = "Override default dynamic prefix for successful delivery"
  type        = string
  default     = null
}

variable "buffering_size_mb" {
  description = "Firehose buffer size in MB (1–128). Larger = fewer small files."
  type        = number
  default     = 128
}

variable "buffering_interval_seconds" {
  description = "Max seconds before flush (60–900)"
  type        = number
  default     = 300
}

variable "compression_format" {
  type    = string
  default = "GZIP"
}

variable "enable_data_format_conversion" {
  description = "Reserved for Parquet conversion via Glue; keep false until schema is ready"
  type        = bool
  default     = false
}

variable "glue_database_name" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
