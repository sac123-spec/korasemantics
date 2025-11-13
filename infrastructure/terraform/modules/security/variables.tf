variable "name" {
  description = "Name prefix applied to security resources"
  type        = string
}

variable "tags" {
  description = "Common tags applied to security resources"
  type        = map(string)
  default     = {}
}

variable "eks_cluster_name" {
  description = "EKS cluster name used by conformance pack checks"
  type        = string
}

variable "guardduty_finding_publishing_frequency" {
  description = "Frequency for publishing GuardDuty findings"
  type        = string
  default     = "SIX_HOURS"
}

variable "securityhub_enabled_standards" {
  description = "List of Security Hub standards identifiers to subscribe to"
  type        = list(string)
  default     = ["aws-foundational-security-best-practices/v/1.0.0"]
}

variable "config_logs_bucket_name" {
  description = "Optional name of an existing S3 bucket for AWS Config delivery. When omitted a dedicated bucket is created."
  type        = string
  default     = null
}

variable "config_bucket_force_destroy" {
  description = "Whether to allow force destroy of the AWS Config delivery bucket"
  type        = bool
  default     = false
}

variable "conformance_pack_name" {
  description = "Name assigned to the AWS Config conformance pack"
  type        = string
  default     = "baseline-security"
}
