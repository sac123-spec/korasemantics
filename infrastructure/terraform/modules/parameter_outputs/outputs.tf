output "parameter_names" {
  description = "Names of parameters that were created"
  value       = { for k, v in aws_ssm_parameter.this : k => v.name }
}
