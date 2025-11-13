variable "name" {
  description = "Identifier used for cluster and related resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC hosting the database"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the subnet group"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect to the database"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to the database"
  type        = list(string)
  default     = []
}

variable "engine" {
  description = "Database engine"
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
}

variable "master_username" {
  description = "Master database username"
  type        = string
}

variable "db_name" {
  description = "Initial database name"
  type        = string
}

variable "port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "backup_retention_period" {
  description = "Days to retain automated backups"
  type        = number
}

variable "preferred_backup_window" {
  description = "Daily time range for backups"
  type        = string
}

variable "preferred_maintenance_window" {
  description = "Weekly time range for maintenance"
  type        = string
}

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key for database encryption"
  type        = string
  default     = null
}

variable "secret_kms_key_id" {
  description = "KMS key for the Secrets Manager secret"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Apply modifications immediately"
  type        = bool
  default     = false
}

variable "instance_class" {
  description = "Instance class for cluster instances"
  type        = string
}

variable "instance_count" {
  description = "Number of cluster instances"
  type        = number
  default     = 1
}

variable "enable_secret_rotation" {
  description = "Enable automatic secret rotation"
  type        = bool
  default     = false
}

variable "rotation_lambda_arn" {
  description = "Lambda ARN used for rotating the secret"
  type        = string
  default     = null
}

variable "rotation_days" {
  description = "Number of days between rotations"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to created resources"
  type        = map(string)
  default     = {}
}
