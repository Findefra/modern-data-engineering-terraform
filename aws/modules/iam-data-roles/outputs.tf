output "redshift_spectrum_role_arn" {
  value = aws_iam_role.redshift_spectrum.arn
}

output "redshift_spectrum_role_name" {
  value = aws_iam_role.redshift_spectrum.name
}
