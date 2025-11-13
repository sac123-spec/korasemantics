variable "name" {
  description = "Name prefix for network resources"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)

  validation {
    condition     = length(var.azs) >= max(length(var.public_subnet_cidrs), length(var.private_subnet_cidrs))
    error_message = "The number of availability zones must cover all subnet CIDR entries."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) > 0
    error_message = "At least one public subnet CIDR must be provided."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) > 0
    error_message = "At least one private subnet CIDR must be provided."
  }
}

variable "control_plane_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the control plane API"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
