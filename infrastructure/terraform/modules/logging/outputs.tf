output "log_bucket_name" {
  description = "Name of the centralized log archive bucket."
  value       = aws_s3_bucket.log_archive.id
}

output "log_bucket_arn" {
  description = "ARN of the centralized log archive bucket."
  value       = aws_s3_bucket.log_archive.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key encrypting the log archive."
  value       = aws_kms_key.log_archive.arn
}

output "kms_key_id" {
  description = "ID of the KMS key encrypting the log archive."
  value       = aws_kms_key.log_archive.key_id
}

output "cloudtrail_trail_arn" {
  description = "ARN of the organization-level CloudTrail."
  value       = aws_cloudtrail.organization.arn
}

output "cloudtrail_log_group_name" {
  description = "CloudWatch Logs group receiving CloudTrail events (if enabled)."
  value       = local.cloudtrail_log_group
}

output "eks_audit_log_group_name" {
  description = "CloudWatch Logs group that should receive EKS audit events (if enabled)."
  value       = local.audit_log_group_name
}

output "cloudtrail_cloudwatch_role_arn" {
  description = "IAM role ARN assumed by CloudTrail for CloudWatch log delivery (if enabled)."
  value       = var.enable_cloudwatch_logs ? aws_iam_role.cloudtrail[0].arn : null
}

output "eks_audit_role_arn" {
  description = "IAM role ARN that Fluent Bit (or similar) should assume via IRSA to ship EKS audit logs (if created)."
  value       = var.enable_eks_audit_log_shipping && var.create_eks_audit_irsa_role ? aws_iam_role.eks_audit[0].arn : null
}
