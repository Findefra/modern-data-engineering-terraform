output "landing_bucket_name" {
  value = google_storage_bucket.zone["landing"].name
}

output "landing_bucket_url" {
  value = google_storage_bucket.zone["landing"].url
}

output "processed_bucket_name" {
  value = google_storage_bucket.zone["processed"].name
}

output "curated_bucket_name" {
  value = google_storage_bucket.zone["curated"].name
}

output "zone_bucket_names" {
  value = { for k, b in google_storage_bucket.zone : k => b.name }
}
