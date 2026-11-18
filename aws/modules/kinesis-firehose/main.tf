###############################################################################
# Kinesis Data Streams + Firehose → S3 (streaming landing)
#
# Real-world notes:
# - Firehose is the pragmatic default for "get events into the lake". Kinesis
#   Streams alone is for when you need fan-out, custom consumers, or sub-second
#   processing. Most teams over-buy Streams and under-use Firehose.
# - Buffer size/interval trade latency vs small-file pain. 128MB / 300s is a
#   sane starting point for Parquet delivery; tighten only if you need fresher data.
# - Dynamic partitioning on Firehose is powerful and easy to misconfigure.
#   Test with real keys before production.
# - MSK is the right choice when you already run Kafka or need exactly-once
#   semantics and multi-consumer fan-out. It is not a drop-in upgrade from
#   Firehose — different operational model and cost profile.
# - Always enable server-side encryption and CloudWatch logging on the delivery
#   stream. Failed delivery without a clear error path is a silent data loss.
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
    Module      = "kinesis-firehose"
    Environment = var.environment
    Project     = var.project_name
  })
  stream_name    = "${var.project_name}-${var.environment}-events"
  firehose_name  = "${var.project_name}-${var.environment}-to-s3"
  prefix_default = "raw/stream/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
}

resource "aws_kinesis_stream" "events" {
  count = var.create_kinesis_stream ? 1 : 0

  name             = local.stream_name
  shard_count      = var.stream_mode == "PROVISIONED" ? var.shard_count : null
  retention_period = var.retention_hours
  encryption_type  = "KMS"
  kms_key_id       = var.kms_key_id != null ? var.kms_key_id : "alias/aws/kinesis"

  stream_mode_details {
    stream_mode = var.stream_mode
  }

  shard_level_metrics = ["IncomingBytes", "OutgoingBytes", "IteratorAgeMilliseconds"]

  tags = local.common_tags
}

data "aws_iam_policy_document" "firehose_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "firehose" {
  name               = "${var.project_name}-${var.environment}-firehose"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "firehose" {
  statement {
    sid    = "S3Delivery"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    resources = [
      var.destination_bucket_arn,
      "${var.destination_bucket_arn}/*"
    ]
  }

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.create_kinesis_stream ? [1] : []
    content {
      sid    = "KinesisSource"
      effect = "Allow"
      actions = [
        "kinesis:DescribeStream",
        "kinesis:GetShardIterator",
        "kinesis:GetRecords",
        "kinesis:ListShards"
      ]
      resources = [aws_kinesis_stream.events[0].arn]
    }
  }

  dynamic "statement" {
    for_each = var.glue_database_name != null ? [1] : []
    content {
      sid    = "GlueCatalog"
      effect = "Allow"
      actions = [
        "glue:GetTable",
        "glue:GetTableVersion",
        "glue:GetTableVersions"
      ]
      resources = ["*"]
    }
  }
}

resource "aws_iam_role_policy" "firehose" {
  name   = "firehose-delivery"
  role   = aws_iam_role.firehose.id
  policy = data.aws_iam_policy_document.firehose.json
}

resource "aws_cloudwatch_log_group" "firehose" {
  name              = "/aws/kinesisfirehose/${local.firehose_name}"
  retention_in_days = 14
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_stream" "firehose_s3" {
  name           = "S3Delivery"
  log_group_name = aws_cloudwatch_log_group.firehose.name
}

resource "aws_kinesis_firehose_delivery_stream" "to_s3" {
  name        = local.firehose_name
  destination = "extended_s3"

  dynamic "kinesis_source_configuration" {
    for_each = var.create_kinesis_stream ? [1] : []
    content {
      kinesis_stream_arn = aws_kinesis_stream.events[0].arn
      role_arn           = aws_iam_role.firehose.arn
    }
  }

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose.arn
    bucket_arn          = var.destination_bucket_arn
    prefix              = coalesce(var.s3_prefix, local.prefix_default)
    error_output_prefix = "errors/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    buffering_size      = var.buffering_size_mb
    buffering_interval  = var.buffering_interval_seconds
    compression_format  = var.compression_format

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_s3.name
    }

    dynamic "processing_configuration" {
      for_each = var.enable_data_format_conversion ? [] : [1]
      content {
        enabled = false
      }
    }
  }

  tags = local.common_tags
}
