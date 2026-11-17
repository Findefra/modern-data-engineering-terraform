output "job_id" {
  value = try(google_dataflow_job.batch_example[0].id, null)
}

output "job_name" {
  value = try(google_dataflow_job.batch_example[0].name, null)
}
