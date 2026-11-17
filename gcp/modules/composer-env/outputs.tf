output "composer_environment_name" {
  value = try(google_composer_environment.this[0].name, null)
}

output "airflow_uri" {
  value = try(google_composer_environment.this[0].config[0].airflow_uri, null)
}

output "gcs_bucket" {
  value = try(google_composer_environment.this[0].config[0].dag_gcs_prefix, null)
}
