###############################################################################
# Complete example — wires the core AWS data engineering modules together.
#
# This is intentionally minimal networking. In real life you already have a
# VPC; pass real private subnet IDs and security groups.
###############################################################################

provider "aws" {
  region = var.aws_region
}

module "data_lake" {
  source = "../../modules/s3-data-lake"

  project_name          = var.project_name
  environment           = var.environment
  force_destroy         = var.force_destroy
  enable_versioning     = true
  enable_access_logging = true
  tags                  = var.tags
}

module "iam" {
  source = "../../modules/iam-data-roles"

  project_name     = var.project_name
  environment      = var.environment
  lake_bucket_arns = [
    module.data_lake.raw_bucket_arn,
    module.data_lake.cleaned_bucket_arn,
    module.data_lake.curated_bucket_arn
  ]
  tags = var.tags
}

module "glue" {
  source = "../../modules/glue-catalog-etl"

  project_name       = var.project_name
  environment        = var.environment
  lake_bucket_arns   = [
    module.data_lake.raw_bucket_arn,
    module.data_lake.cleaned_bucket_arn,
    module.data_lake.curated_bucket_arn
  ]
  raw_bucket_id      = module.data_lake.raw_bucket_id
  cleaned_bucket_id  = module.data_lake.cleaned_bucket_id
  create_raw_crawler = true
  create_example_job = false
  tags               = var.tags
}

# Redshift Serverless is optional in the example so you can apply storage + Glue first.
module "redshift" {
  count  = var.enable_redshift ? 1 : 0
  source = "../../modules/redshift-serverless"

  project_name        = var.project_name
  environment         = var.environment
  admin_password      = var.redshift_admin_password
  base_capacity_rpu   = var.redshift_base_rpu
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = var.redshift_security_group_ids
  iam_role_arns       = [module.iam.redshift_spectrum_role_arn]
  tags                = var.tags
}
