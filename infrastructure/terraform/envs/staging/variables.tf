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
