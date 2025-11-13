variable "name" {
  description = "Friendly name used to prefix resources."
  type        = string
}

variable "organization_id" {
  description = "AWS Organization ID used to scope CloudTrail log delivery paths."
  type        = string
}

variable "trail_name" {
  description = "Name of the organization-level CloudTrail."
  type        = string
  default     = null
}

variable "log_bucket_name" {
  description = "Optional pre-existing S3 bucket name for storing aggregated logs."
  type        = string
  default     = null
}

variable "log_bucket_force_destroy" {
  description = "Allow Terraform to delete the log archive bucket even when objects remain."
  type        = bool
  default     = false
}

variable "kms_key_deletion_window_in_days" {
  description = "Waiting period before the log archive KMS key is deleted."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Common tags to apply to all managed resources."
  type        = map(string)
  default     = {}
}

variable "enable_cloudwatch_logs" {
  description = "Whether to stream CloudTrail events to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "cloudtrail_log_group_name" {
  description = "Optional name for the CloudTrail CloudWatch log group."
  type        = string
  default     = null
}

variable "cloudtrail_log_retention_in_days" {
  description = "Retention period for CloudTrail events stored in CloudWatch Logs."
  type        = number
  default     = 365
}

variable "enable_eks_audit_log_shipping" {
  description = "Enable shipping of EKS control-plane audit logs to the log archive."
  type        = bool
  default     = true
}

variable "create_dedicated_audit_log_group" {
  description = "Create a dedicated CloudWatch Logs group for EKS audit records instead of reusing the CloudTrail group."
  type        = bool
  default     = false
}

variable "eks_audit_log_group_name" {
  description = "Optional name for the dedicated EKS audit CloudWatch log group."
  type        = string
  default     = null
}

variable "eks_audit_log_retention_in_days" {
  description = "Retention period for EKS audit events stored in CloudWatch Logs."
  type        = number
  default     = 90
}

variable "create_eks_audit_irsa_role" {
  description = "Whether to create an IRSA-compatible IAM role for a Fluent Bit DaemonSet to push audit logs."
  type        = bool
  default     = true
}

variable "eks_oidc_provider_arn" {
  description = "OIDC provider ARN associated with the target EKS cluster (required when creating the IRSA role)."
  type        = string
  default     = null
}

variable "eks_audit_service_account_namespace" {
  description = "Namespace that hosts the Fluent Bit (or similar) DaemonSet responsible for shipping audit logs."
  type        = string
  default     = "logging"
}

variable "eks_audit_service_account_name" {
  description = "Service account used by the DaemonSet that ships audit logs."
  type        = string
  default     = "fluent-bit"
}

variable "cloudtrail_insight_selectors" {
  description = "Optional list of insight selectors to enable for CloudTrail."
  type = list(object({
    insight_type = string
  }))
  default = []
}
