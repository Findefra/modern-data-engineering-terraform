###############################################################################
# Redshift Serverless Module
#
# Real-world notes:
# - Serverless is the right default for most new workloads. You pay for RPU
#   usage, not for idle clusters.
# - Still put it in private subnets. Publicly accessible Redshift is almost
#   never the right answer.
# - Base capacity (RPU) is the main cost lever. Start low, raise when queries
#   queue. Many teams over-provision base capacity "just in case".
# - Spectrum / external schemas let you query the lake without loading
#   everything. Use them deliberately — they are not free and have different
#   performance characteristics.
# - Admin credentials should live in Secrets Manager, not in Terraform state
#   as plain text if you can avoid it.
###############################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  common_tags = merge(var.tags, {
    Module      = "redshift-serverless"
    Environment = var.environment
    Project     = var.project_name
  })
}

resource "aws_redshiftserverless_namespace" "this" {
  namespace_name      = "${var.project_name}-${var.environment}"
  db_name             = var.db_name
  admin_username      = var.admin_username
  admin_user_password = var.admin_password # prefer Secrets Manager in real use

  iam_roles = var.iam_role_arns

  tags = local.common_tags
}

resource "aws_redshiftserverless_workgroup" "this" {
  workgroup_name = "${var.project_name}-${var.environment}-wg"
  namespace_name  = aws_redshiftserverless_namespace.this.namespace_name

  base_capacity = var.base_capacity_rpu
  max_capacity  = var.max_capacity_rpu

  publicly_accessible = false
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids

  config_parameter {
    parameter_key   = "enable_user_activity_logging"
    parameter_value = "true"
  }

  config_parameter {
    parameter_key   = "require_ssl"
    parameter_value = "true"
  }

  tags = local.common_tags
}
