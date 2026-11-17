output "raw_bucket" {
  value = module.data_lake.raw_bucket_id
}

output "cleaned_bucket" {
  value = module.data_lake.cleaned_bucket_id
}

output "curated_bucket" {
  value = module.data_lake.curated_bucket_id
}

output "glue_database" {
  value = module.glue.glue_database_name
}

output "glue_role_arn" {
  value = module.glue.glue_role_arn
}

output "redshift_endpoint" {
  value = try(module.redshift[0].endpoint, null)
}
