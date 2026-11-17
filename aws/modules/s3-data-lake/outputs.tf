output "raw_bucket_id" {
  description = "Raw (Bronze) bucket ID"
  value       = aws_s3_bucket.zone["raw"].id
}

output "raw_bucket_arn" {
  value = aws_s3_bucket.zone["raw"].arn
}

output "cleaned_bucket_id" {
  description = "Cleaned (Silver) bucket ID"
  value       = aws_s3_bucket.zone["cleaned"].id
}

output "cleaned_bucket_arn" {
  value = aws_s3_bucket.zone["cleaned"].arn
}

output "curated_bucket_id" {
  description = "Curated (Gold) bucket ID"
  value       = aws_s3_bucket.zone["curated"].id
}

output "curated_bucket_arn" {
  value = aws_s3_bucket.zone["curated"].arn
}

output "access_logs_bucket_id" {
  value = try(aws_s3_bucket.access_logs[0].id, null)
}

output "zone_bucket_ids" {
  description = "Map of zone name → bucket id"
  value = {
    for k, b in aws_s3_bucket.zone : k => b.id
  }
}
