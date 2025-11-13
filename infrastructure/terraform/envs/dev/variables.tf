variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = [
    "10.10.0.0/20",
    "10.10.16.0/20"
  ]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = [
    "10.10.32.0/20",
    "10.10.48.0/20"
  ]
}

variable "cluster_version" {
  description = "EKS version"
  type        = string
  default     = "1.29"
}

variable "artifact_bucket_name" {
  description = "Name of the artifact storage bucket"
  type        = string
  default     = "korasemantics-dev-artifacts"
}

variable "artifact_bucket_force_destroy" {
  description = "Force destroy the artifact bucket on teardown"
  type        = bool
  default     = true
}

variable "artifact_bucket_block_public_access" {
  description = "Block all public access to the artifact bucket"
  type        = bool
  default     = true
}

variable "artifact_bucket_versioning_enabled" {
  description = "Enable versioning on the artifact bucket"
  type        = bool
  default     = true
}

variable "artifact_bucket_kms_key_arn" {
  description = "KMS key ARN used for bucket encryption"
  type        = string
  default     = null
}

variable "artifact_bucket_lifecycle_rules" {
  description = "Lifecycle rules for the artifact bucket"
  type = list(object({
    id                                     = string
    status                                 = string
    prefix                                 = optional(string)
    tags                                   = optional(map(string))
    transitions                            = optional(list(object({
      days          = optional(number)
      storage_class = string
    })))
    expiration                             = optional(object({
      days                         = optional(number)
      date                         = optional(string)
      expired_object_delete_marker = optional(bool)
    }))
    noncurrent_version_transitions          = optional(list(object({
      newer_noncurrent_versions = optional(number)
      noncurrent_days           = optional(number)
      storage_class             = string
    })))
    noncurrent_version_expiration           = optional(object({
      newer_noncurrent_versions = optional(number)
      noncurrent_days           = optional(number)
    }))
    abort_incomplete_multipart_upload_days = optional(number)
  }))
  default = [
    {
      id     = "expire-temporary-artifacts"
      status = "Enabled"
      prefix = "tmp/"
      expiration = {
        days = 7
      }
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        }
      ]
    }
  ]
}

variable "efs_performance_mode" {
  description = "Performance mode for the shared EFS"
  type        = string
  default     = "generalPurpose"
}

variable "efs_throughput_mode" {
  description = "Throughput mode for the shared EFS"
  type        = string
  default     = "bursting"
}

variable "efs_provisioned_throughput_in_mibps" {
  description = "Provisioned throughput when using provisioned mode"
  type        = number
  default     = null
}

variable "efs_encrypted" {
  description = "Encrypt the EFS file system"
  type        = bool
  default     = true
}

variable "efs_kms_key_arn" {
  description = "KMS key ARN for the EFS file system"
  type        = string
  default     = null
}

variable "efs_backup_policy_enabled" {
  description = "Enable AWS Backup on the EFS file system"
  type        = bool
  default     = false
}

variable "metadata_db_engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "15.3"
}

variable "metadata_db_master_username" {
  description = "Master username for the metadata database"
  type        = string
  default     = "metadata_admin"
}

variable "metadata_db_name" {
  description = "Initial database name for metadata"
  type        = string
  default     = "metadata"
}

variable "metadata_db_port" {
  description = "Port the metadata database listens on"
  type        = number
  default     = 5432
}

variable "metadata_db_instance_class" {
  description = "Instance class for the metadata database"
  type        = string
  default     = "db.t4g.medium"
}

variable "metadata_db_instance_count" {
  description = "Number of database instances"
  type        = number
  default     = 1
}

variable "metadata_db_backup_retention_period" {
  description = "Automated backup retention in days"
  type        = number
  default     = 3
}

variable "metadata_db_preferred_backup_window" {
  description = "Daily time range for automated backups"
  type        = string
  default     = "04:00-06:00"
}

variable "metadata_db_preferred_maintenance_window" {
  description = "Weekly time range for maintenance"
  type        = string
  default     = "sun:07:00-sun:09:00"
}

variable "metadata_db_storage_encrypted" {
  description = "Enable storage encryption on the metadata database"
  type        = bool
  default     = true
}

variable "metadata_db_kms_key_arn" {
  description = "KMS key ARN for database storage encryption"
  type        = string
  default     = null
}

variable "metadata_db_secret_kms_key_arn" {
  description = "KMS key ARN for the Secrets Manager secret"
  type        = string
  default     = null
}

variable "metadata_db_deletion_protection" {
  description = "Enable deletion protection for the metadata database"
  type        = bool
  default     = false
}

variable "metadata_db_skip_final_snapshot" {
  description = "Skip the final snapshot when destroying the metadata database"
  type        = bool
  default     = true
}

variable "metadata_db_apply_immediately" {
  description = "Apply metadata database changes immediately"
  type        = bool
  default     = true
}

variable "metadata_db_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the metadata database"
  type        = list(string)
  default     = []
}

variable "metadata_db_enable_secret_rotation" {
  description = "Enable automatic rotation for the metadata database secret"
  type        = bool
  default     = false
}

variable "metadata_db_rotation_lambda_arn" {
  description = "Lambda ARN used to rotate the metadata database secret"
  type        = string
  default     = null
}

variable "metadata_db_rotation_days" {
  description = "Days between secret rotations"
  type        = number
  default     = 30
}

variable "parameter_store_prefix" {
  description = "Prefix used when publishing outputs to SSM Parameter Store"
  type        = string
  default     = "/korasemantics/dev/"
}
