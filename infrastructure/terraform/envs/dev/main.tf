terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name_prefix = "korasemantics-dev"
  tags = {
    Environment = "dev"
    Terraform   = "true"
    Project     = "KorA Semantics"
  }

  azs = slice(data.aws_availability_zones.available.names, 0, length(var.public_subnet_cidrs))
}

module "network" {
  source                 = "../../modules/network"
  name                   = local.name_prefix
  cidr_block             = var.vpc_cidr
  azs                    = local.azs
  public_subnet_cidrs    = var.public_subnet_cidrs
  private_subnet_cidrs   = var.private_subnet_cidrs
  control_plane_ingress_cidrs = var.control_plane_ingress_cidrs
  tags                   = local.tags
}

module "eks" {
  source                           = "../../modules/eks"
  name                             = "${local.name_prefix}-cluster"
  vpc_id                           = module.network.vpc_id
  subnet_ids                       = module.network.private_subnet_ids
  control_plane_security_group_id  = module.network.control_plane_security_group_id
  data_plane_security_group_id     = module.network.data_plane_security_group_id
  cluster_version                  = var.cluster_version
  cluster_log_types                = var.cluster_log_types
  cluster_log_retention_in_days    = var.cluster_log_retention_in_days
  tags                             = local.tags
  node_groups = {
    system = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 3
      labels = {
        role = "system"
      }
    }
    workloads = {
      instance_types = ["m5.large"]
      desired_size   = 2
      min_size       = 1
      max_size       = 4
      capacity_type  = "SPOT"
      labels = {
        role = "workload"
      }
    }
  }
}

module "monitoring" {
  source                       = "../../modules/monitoring"
  name                         = local.name_prefix
  vpc_id                       = module.network.vpc_id
  eks_cluster_name             = module.eks.cluster_name
  tags                         = local.tags
  flow_log_retention_in_days   = var.monitoring_flow_log_retention_in_days
  alarm_period                 = var.monitoring_alarm_period
  alarm_evaluation_periods     = var.monitoring_alarm_evaluation_periods
  alarm_threshold              = var.monitoring_alarm_threshold
  notification_emails          = var.monitoring_notification_emails
  xray_fixed_rate              = var.monitoring_xray_fixed_rate
}

module "security" {
  source                              = "../../modules/security"
  name                                = local.name_prefix
  tags                                = local.tags
  eks_cluster_name                    = module.eks.cluster_name
  guardduty_finding_publishing_frequency = var.security_guardduty_finding_publishing_frequency
  securityhub_enabled_standards       = var.securityhub_enabled_standards
  config_logs_bucket_name             = var.security_config_logs_bucket_name
  config_bucket_force_destroy         = var.security_config_bucket_force_destroy
  conformance_pack_name               = var.security_conformance_pack_name
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
