variable "name" {
  description = "Name prefix used for monitoring resources"
  type        = string
}

variable "tags" {
  description = "Common tags applied to monitoring resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC identifier to enable flow logs"
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS cluster name for alarms and log targeting"
  type        = string
}

variable "flow_log_retention_in_days" {
  description = "Retention for VPC flow log CloudWatch log group"
  type        = number
  default     = 90
}

variable "alarm_period" {
  description = "Period in seconds for the EKS failed node count alarm"
  type        = number
  default     = 300
}

variable "alarm_evaluation_periods" {
  description = "Number of periods for evaluating the EKS failed node count alarm"
  type        = number
  default     = 1
}

variable "alarm_threshold" {
  description = "Threshold for the EKS failed node count alarm"
  type        = number
  default     = 1
}

variable "notification_emails" {
  description = "Email addresses subscribed to monitoring alerts"
  type        = list(string)
  default     = []
}

variable "xray_fixed_rate" {
  description = "Sampling rate for the default AWS X-Ray sampling rule"
  type        = number
  default     = 0.05
}
