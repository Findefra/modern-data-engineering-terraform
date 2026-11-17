###############################################################################
# Step Functions Orchestration (skeleton)
#
# Real-world: start with a simple linear state machine that calls Glue jobs.
# Add branching, Parallel, Map, and error handling as the pipeline matures.
# Avoid putting business logic in the state machine itself — keep it thin.
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
    Module      = "step-functions-orchestration"
    Environment = var.environment
    Project     = var.project_name
  })
}

data "aws_iam_policy_document" "sfn_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sfn" {
  name               = "${var.project_name}-${var.environment}-sfn-role"
  assume_role_policy = data.aws_iam_policy_document.sfn_assume.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "sfn_glue" {
  statement {
    effect = "Allow"
    actions = [
      "glue:StartJobRun",
      "glue:GetJobRun",
      "glue:GetJobRuns",
      "glue:BatchStopJobRun"
    ]
    resources = ["*"] # tighten to specific job ARNs in production
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "sfn_glue" {
  name   = "sfn-glue"
  role   = aws_iam_role.sfn.id
  policy = data.aws_iam_policy_document.sfn_glue.json
}

resource "aws_sfn_state_machine" "etl" {
  name     = "${var.project_name}-${var.environment}-etl"
  role_arn = aws_iam_role.sfn.arn

  definition = jsonencode({
    Comment = "Basic ETL orchestration — extend with real job names and error handling"
    StartAt = "RunGlueJob"
    States = {
      RunGlueJob = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = var.glue_job_name
        }
        End = true
      }
    }
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.sfn.arn}:*"
    include_execution_data = true
    level                  = "ERROR"
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "sfn" {
  name              = "/aws/vendedlogs/states/${var.project_name}-${var.environment}-etl"
  retention_in_days = 30
  tags              = local.common_tags
}
