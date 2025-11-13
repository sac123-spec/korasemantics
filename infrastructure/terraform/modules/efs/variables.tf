variable "name" {
  description = "Name prefix for the EFS file system"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for security group association"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets to create mount targets in"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed ingress to the EFS mount targets"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed ingress to the EFS mount targets"
  type        = list(string)
  default     = []
}

variable "performance_mode" {
  description = "File system performance mode"
  type        = string
  default     = "generalPurpose"
}

variable "throughput_mode" {
  description = "File system throughput mode"
  type        = string
  default     = "bursting"
}

variable "provisioned_throughput_in_mibps" {
  description = "Provisioned throughput in MiB/s when using provisioned throughput mode"
  type        = number
  default     = null
}

variable "encrypted" {
  description = "Encrypt the file system"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key for encrypting the file system"
  type        = string
  default     = null
}

variable "backup_policy_enabled" {
  description = "Enable AWS Backup for the file system"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to created resources"
  type        = map(string)
  default     = {}
}
