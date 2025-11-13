terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
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
  source               = "../../modules/network"
  name                 = local.name_prefix
  cidr_block           = var.vpc_cidr
  azs                  = local.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = local.tags
}

module "eks" {
  source                          = "../../modules/eks"
  name                            = "${local.name_prefix}-cluster"
  vpc_id                          = module.network.vpc_id
  subnet_ids                      = module.network.private_subnet_ids
  control_plane_security_group_id = module.network.control_plane_security_group_id
  data_plane_security_group_id    = module.network.data_plane_security_group_id
  cluster_version                 = var.cluster_version
  tags                            = local.tags
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

module "artifacts_bucket" {
  source                 = "../../modules/s3_bucket"
  bucket_name            = var.artifact_bucket_name
  force_destroy          = var.artifact_bucket_force_destroy
  versioning_enabled     = var.artifact_bucket_versioning_enabled
  block_public_access    = var.artifact_bucket_block_public_access
  encryption_kms_key_id  = var.artifact_bucket_kms_key_arn
  lifecycle_rules        = var.artifact_bucket_lifecycle_rules
  tags                   = local.tags
}

module "shared_filesystem" {
  source                          = "../../modules/efs"
  name                            = "${local.name_prefix}-shared"
  vpc_id                          = module.network.vpc_id
  subnet_ids                      = module.network.private_subnet_ids
  allowed_security_group_ids      = [module.network.data_plane_security_group_id]
  performance_mode                = var.efs_performance_mode
  throughput_mode                 = var.efs_throughput_mode
  provisioned_throughput_in_mibps = var.efs_provisioned_throughput_in_mibps
  encrypted                       = var.efs_encrypted
  kms_key_id                      = var.efs_kms_key_arn
  backup_policy_enabled           = var.efs_backup_policy_enabled
  tags                            = local.tags
}

module "metadata_database" {
  source                        = "../../modules/metadata_db"
  name                          = "${local.name_prefix}-metadata"
  vpc_id                        = module.network.vpc_id
  subnet_ids                    = module.network.private_subnet_ids
  allowed_security_group_ids    = [module.network.data_plane_security_group_id]
  allowed_cidr_blocks           = var.metadata_db_allowed_cidr_blocks
  engine_version                = var.metadata_db_engine_version
  master_username               = var.metadata_db_master_username
  db_name                       = var.metadata_db_name
  port                          = var.metadata_db_port
  backup_retention_period       = var.metadata_db_backup_retention_period
  preferred_backup_window       = var.metadata_db_preferred_backup_window
  preferred_maintenance_window  = var.metadata_db_preferred_maintenance_window
  storage_encrypted             = var.metadata_db_storage_encrypted
  kms_key_id                    = var.metadata_db_kms_key_arn
  secret_kms_key_id             = var.metadata_db_secret_kms_key_arn
  deletion_protection           = var.metadata_db_deletion_protection
  skip_final_snapshot           = var.metadata_db_skip_final_snapshot
  apply_immediately             = var.metadata_db_apply_immediately
  instance_class                = var.metadata_db_instance_class
  instance_count                = var.metadata_db_instance_count
  enable_secret_rotation        = var.metadata_db_enable_secret_rotation
  rotation_lambda_arn           = var.metadata_db_rotation_lambda_arn
  rotation_days                 = var.metadata_db_rotation_days
  tags                          = local.tags
}

module "parameter_outputs" {
  source           = "../../modules/parameter_outputs"
  parameter_prefix = var.parameter_store_prefix
  tags             = local.tags
  parameters = {
    "network/vpc_id" = {
      value       = module.network.vpc_id
      description = "VPC identifier for the environment"
    }
    "eks/cluster_endpoint" = {
      value       = module.eks.cluster_endpoint
      description = "EKS cluster API endpoint"
    }
    "storage/artifacts_bucket" = {
      value       = module.artifacts_bucket.bucket_name
      description = "Primary artifact bucket"
    }
    "storage/efs_file_system_id" = {
      value       = module.shared_filesystem.file_system_id
      description = "Shared EFS file system"
    }
    "database/secret_arn" = {
      value       = module.metadata_database.secret_arn
      description = "Secret storing database credentials"
    }
  }
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "artifacts_bucket_name" {
  value = module.artifacts_bucket.bucket_name
}

output "efs_file_system_id" {
  value = module.shared_filesystem.file_system_id
}

output "metadata_db_endpoint" {
  value = module.metadata_database.cluster_endpoint
}

output "metadata_db_secret_arn" {
  value = module.metadata_database.secret_arn
}

output "parameter_store_paths" {
  value = module.parameter_outputs.parameter_names
}
