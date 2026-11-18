output "table_names" {
  value = [for t in aws_glue_catalog_table.iceberg : t.name]
}

output "table_ids" {
  value = { for k, t in aws_glue_catalog_table.iceberg : k => t.id }
}
