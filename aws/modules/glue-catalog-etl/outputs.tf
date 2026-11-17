output "glue_database_name" {
  value = aws_glue_catalog_database.this.name
}

output "glue_role_arn" {
  value = aws_iam_role.glue.arn
}

output "glue_role_name" {
  value = aws_iam_role.glue.name
}

output "raw_crawler_name" {
  value = try(aws_glue_crawler.raw[0].name, null)
}

output "example_job_name" {
  value = try(aws_glue_job.etl_example[0].name, null)
}
