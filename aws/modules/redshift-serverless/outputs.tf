output "namespace_name" {
  value = aws_redshiftserverless_namespace.this.namespace_name
}

output "namespace_arn" {
  value = aws_redshiftserverless_namespace.this.arn
}

output "workgroup_name" {
  value = aws_redshiftserverless_workgroup.this.workgroup_name
}

output "workgroup_arn" {
  value = aws_redshiftserverless_workgroup.this.arn
}

output "endpoint" {
  description = "Workgroup endpoint (host)"
  value       = try(aws_redshiftserverless_workgroup.this.endpoint[0].address, null)
}

output "port" {
  value = try(aws_redshiftserverless_workgroup.this.endpoint[0].port, 5439)
}
