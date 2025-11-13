output "file_system_id" {
  description = "ID of the EFS file system"
  value       = aws_efs_file_system.this.id
}

output "file_system_arn" {
  description = "ARN of the EFS file system"
  value       = aws_efs_file_system.this.arn
}

output "security_group_id" {
  description = "Security group protecting the EFS mount targets"
  value       = aws_security_group.efs.id
}

output "mount_targets" {
  description = "Map of mount target IDs by subnet"
  value       = { for k, v in aws_efs_mount_target.this : k => v.id }
}
