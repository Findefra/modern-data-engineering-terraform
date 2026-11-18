output "firehose_arn" {
  value = aws_kinesis_firehose_delivery_stream.to_s3.arn
}

output "firehose_name" {
  value = aws_kinesis_firehose_delivery_stream.to_s3.name
}

output "kinesis_stream_arn" {
  value = try(aws_kinesis_stream.events[0].arn, null)
}

output "kinesis_stream_name" {
  value = try(aws_kinesis_stream.events[0].name, null)
}

output "firehose_role_arn" {
  value = aws_iam_role.firehose.arn
}
