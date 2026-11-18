output "topic_id" {
  value = google_pubsub_topic.events.id
}

output "topic_name" {
  value = google_pubsub_topic.events.name
}

output "subscription_id" {
  value = google_pubsub_subscription.events.id
}

output "dlq_topic_id" {
  value = google_pubsub_topic.dlq.id
}

output "dataflow_job_id" {
  value = try(google_dataflow_job.streaming[0].id, null)
}
