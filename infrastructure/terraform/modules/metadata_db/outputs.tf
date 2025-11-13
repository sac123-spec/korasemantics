output "cluster_endpoint" {
  description = "Writer endpoint for the metadata database"
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Reader endpoint for the metadata database"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "secret_arn" {
  description = "Secrets Manager secret ARN containing database credentials"
  value       = aws_secretsmanager_secret.this.arn
}

output "security_group_id" {
  description = "Security group guarding the database"
  value       = aws_security_group.this.id
}

output "subnet_group_name" {
  description = "Subnet group used by the cluster"
  value       = aws_db_subnet_group.this.name
}
