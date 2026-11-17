output "pipeline_service_account_email" {
  value = google_service_account.data_pipeline.email
}

output "pipeline_service_account_name" {
  value = google_service_account.data_pipeline.name
}
