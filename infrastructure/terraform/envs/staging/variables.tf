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
