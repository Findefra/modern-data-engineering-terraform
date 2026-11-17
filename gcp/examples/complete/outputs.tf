output "landing_bucket" {
  value = module.data_lake.landing_bucket_name
}

output "processed_bucket" {
  value = module.data_lake.processed_bucket_name
}

output "curated_bucket" {
  value = module.data_lake.curated_bucket_name
}

output "bq_raw_dataset" {
  value = module.bigquery.raw_dataset_id
}

output "bq_curated_dataset" {
  value = module.bigquery.curated_dataset_id
}

output "pipeline_sa" {
  value = module.iam.pipeline_service_account_email
}
