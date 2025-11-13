variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = [
    "10.20.0.0/20",
    "10.20.16.0/20",
    "10.20.32.0/20"
  ]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = [
    "10.20.64.0/20",
    "10.20.80.0/20",
    "10.20.96.0/20"
  ]
}

variable "control_plane_ingress_cidrs" {
  description = "CIDR blocks permitted to reach the EKS control plane"
  type        = list(string)
  default     = [
    "10.20.0.0/16"
  ]
}

variable "cluster_version" {
  description = "EKS version"
  type        = string
  default     = "1.29"
}

variable "cluster_log_types" {
  description = "Control plane log types to enable for the EKS cluster"
  type        = list(string)
  default = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

variable "cluster_log_retention_in_days" {
  description = "Retention in days for the EKS control plane log group"
  type        = number
  default     = 90
}

variable "monitoring_flow_log_retention_in_days" {
  description = "Retention in days for the VPC flow log group"
  type        = number
  default     = 120
}

variable "monitoring_alarm_period" {
  description = "CloudWatch alarm period in seconds for failed EKS nodes"
  type        = number
  default     = 300
}

variable "monitoring_alarm_evaluation_periods" {
  description = "Number of periods to evaluate for the failed node alarm"
  type        = number
  default     = 2
}

variable "monitoring_alarm_threshold" {
  description = "Threshold for failed node count before alarming"
  type        = number
  default     = 1
}

variable "monitoring_notification_emails" {
  description = "Email recipients for monitoring alerts"
  type        = list(string)
  default     = []
}

variable "monitoring_xray_fixed_rate" {
  description = "Default sampling rate for the AWS X-Ray rule"
  type        = number
  default     = 0.1
}

variable "security_guardduty_finding_publishing_frequency" {
  description = "Frequency for GuardDuty finding exports"
  type        = string
  default     = "FIFTEEN_MINUTES"
}

variable "securityhub_enabled_standards" {
  description = "Identifiers of Security Hub standards to enable"
  type        = list(string)
  default = [
    "aws-foundational-security-best-practices/v/1.0.0",
    "cis-aws-foundations-benchmark/v/1.4.0"
  ]
}

variable "security_config_logs_bucket_name" {
  description = "Optional pre-created bucket for AWS Config snapshots"
  type        = string
  default     = null
}

variable "security_config_bucket_force_destroy" {
  description = "Allow force destroy of the AWS Config snapshot bucket"
  type        = bool
  default     = false
}

variable "security_conformance_pack_name" {
  description = "Name for the AWS Config conformance pack"
  type        = string
  default     = "korasemantics-staging-baseline"
}

variable "organization_id" {
  description = "AWS Organization ID used by the centralized logging trail"
  type        = string
  default     = "o-example"
}

variable "logging_trail_name" {
  description = "Optional override for the organization-level CloudTrail name"
  type        = string
  default     = null
}

variable "logging_log_bucket_name" {
  description = "Optional pre-created bucket name for centralized logs"
  type        = string
  default     = null
}

variable "logging_force_destroy_log_bucket" {
  description = "Allow Terraform to purge the centralized log bucket"
  type        = bool
  default     = false
}

variable "logging_kms_key_deletion_window_in_days" {
  description = "Waiting period before deleting the log archive KMS key"
  type        = number
  default     = 30
}

variable "logging_enable_cloudwatch_logs" {
  description = "Stream CloudTrail events into CloudWatch Logs"
  type        = bool
  default     = true
}

variable "logging_cloudtrail_log_group_name" {
  description = "Optional CloudWatch Logs group name for CloudTrail"
  type        = string
  default     = null
}

variable "logging_cloudtrail_log_retention_in_days" {
  description = "Retention period for CloudTrail events in CloudWatch Logs"
  type        = number
  default     = 730
}

variable "logging_cloudtrail_insight_selectors" {
  description = "Insight selectors to enable on the organization trail"
  type        = list(object({
    insight_type = string
  }))
  default = []
}

variable "logging_enable_eks_audit_log_shipping" {
  description = "Enable ingestion of cluster audit logs into the archive"
  type        = bool
  default     = true
}

variable "logging_create_dedicated_audit_log_group" {
  description = "Create a dedicated CloudWatch Logs group for audit events"
  type        = bool
  default     = true
}

variable "logging_eks_audit_log_group_name" {
  description = "Optional dedicated audit CloudWatch Logs group name"
  type        = string
  default     = null
}

variable "logging_eks_audit_log_retention_in_days" {
  description = "Retention period for EKS audit events"
  type        = number
  default     = 365
}

variable "logging_enable_eks_audit_irsa_role" {
  description = "Provision the Fluent Bit IRSA role for audit shipping"
  type        = bool
  default     = true
}

variable "logging_eks_audit_service_account_namespace" {
  description = "Namespace hosting the Fluent Bit DaemonSet"
  type        = string
  default     = "logging"
}

variable "logging_eks_audit_service_account_name" {
  description = "Service account name assumed by Fluent Bit"
  type        = string
  default     = "fluent-bit"
}
