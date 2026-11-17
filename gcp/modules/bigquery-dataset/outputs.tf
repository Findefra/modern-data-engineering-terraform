output "raw_dataset_id" {
  value = google_bigquery_dataset.raw.dataset_id
}

output "processed_dataset_id" {
  value = google_bigquery_dataset.processed.dataset_id
}

output "curated_dataset_id" {
  value = google_bigquery_dataset.curated.dataset_id
}

output "raw_dataset_self_link" {
  value = google_bigquery_dataset.raw.self_link
}
