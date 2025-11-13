variable "name" {
  description = "Cluster name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the cluster"
  type        = list(string)
}

variable "control_plane_security_group_id" {
  description = "Security group for the control plane"
  type        = string
}

variable "data_plane_security_group_id" {
  description = "Security group for the nodes"
  type        = string
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "cluster_log_types" {
  description = "EKS control plane log types to enable"
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
  description = "Retention period in days for the EKS control plane CloudWatch log group"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "node_groups" {
  description = "Map of managed node group configurations"
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    capacity_type  = optional(string, "ON_DEMAND")
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = {}
}
