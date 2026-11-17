###############################################################################
# Complete GCP example — GCS lake + BigQuery datasets + pipeline SA
###############################################################################

provider "google" {
  project = var.project_id
  region  = var.region
}

module "data_lake" {
  source = "../../modules/gcs-data-lake"

  project_id    = var.project_id
  project_name  = var.project_name
  environment   = var.environment
  location      = var.location
  force_destroy = var.force_destroy
  labels        = var.labels
}

module "bigquery" {
  source = "../../modules/bigquery-dataset"

  project_id                 = var.project_id
  project_name               = var.project_name
  environment                = var.environment
  location                   = var.location
  delete_contents_on_destroy = var.force_destroy
  labels                     = var.labels
}

module "iam" {
  source = "../../modules/iam-data-roles"

  project_id   = var.project_id
  project_name = var.project_name
  environment  = var.environment
}

# Composer is off by default — turn on only when you actually need Airflow
module "composer" {
  source = "../../modules/composer-env"

  enable_composer         = var.enable_composer
  project_id              = var.project_id
  project_name            = var.project_name
  environment             = var.environment
  region                  = var.region
  service_account_email   = module.iam.pipeline_service_account_email
  labels                  = var.labels
}
