###############################################################################
# Iceberg tables via Glue Data Catalog
#
# Real-world notes:
# - Prefer Iceberg over Hive-style Parquet for any table you will update,
#   evolve, or time-travel. MSCK REPAIR is technical debt.
# - Table location should sit under the Cleaned or Curated bucket, never Raw.
# - Partition keys in the table parameters must match how writers actually
#   write; mismatch = empty queries and confusion.
# - Compaction / snapshot expiration is operational work. Plan jobs for it
#   (Glue or Spark) or you will pay for metadata bloat.
# - S3 Tables (managed Iceberg) is an alternative when you want AWS to own
#   more of the table maintenance. This module stays on classic Glue Catalog
#   Iceberg so it works with Athena, Spark, Redshift Spectrum, and EMR.
###############################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  common_tags = merge(var.tags, {
    Module      = "iceberg-tables"
    Environment = var.environment
    Project     = var.project_name
  })
}

resource "aws_glue_catalog_table" "iceberg" {
  for_each = { for t in var.tables : t.name => t }

  name          = each.value.name
  database_name = var.database_name
  table_type    = "EXTERNAL_TABLE"
  description   = try(each.value.description, "Iceberg table managed by Terraform")

  parameters = merge(
    {
      table_type                 = "ICEBERG"
      "metadata_location"        = "${trimsuffix(each.value.location, "/")}/metadata/"
      "write.format.default"     = try(each.value.write_format, "parquet")
      "write.parquet.compression-codec" = try(each.value.compression, "zstd")
    },
    try(each.value.extra_parameters, {})
  )

  storage_descriptor {
    location      = each.value.location
    input_format  = "org.apache.iceberg.mr.hive.HiveIcebergInputFormat"
    output_format = "org.apache.iceberg.mr.hive.HiveIcebergOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.iceberg.mr.hive.HiveIcebergSerDe"
    }

    dynamic "columns" {
      for_each = each.value.columns
      content {
        name    = columns.value.name
        type    = columns.value.type
        comment = try(columns.value.comment, null)
      }
    }
  }

  dynamic "partition_keys" {
    for_each = try(each.value.partition_keys, [])
    content {
      name = partition_keys.value.name
      type = partition_keys.value.type
    }
  }
}
