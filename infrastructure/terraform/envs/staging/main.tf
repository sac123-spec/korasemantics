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
  name_prefix = "korasemantics-staging"
  tags = {
    Environment = "staging"
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
  tags                             = local.tags
  node_groups = {
    system = {
      instance_types = ["t3.large"]
      desired_size   = 3
      min_size       = 2
      max_size       = 5
      labels = {
        role = "system"
      }
    }
    workloads = {
      instance_types = ["m5.xlarge"]
      desired_size   = 3
      min_size       = 2
      max_size       = 6
      capacity_type  = "ON_DEMAND"
      labels = {
        role = "workload"
      }
    }
    analytics = {
      instance_types = ["r6i.xlarge"]
      desired_size   = 2
      min_size       = 1
      max_size       = 4
      capacity_type  = "SPOT"
      labels = {
        role = "analytics"
      }
      taints = [
        {
          key    = "dedicated"
          value  = "analytics"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
