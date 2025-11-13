# Terraform Infrastructure

This directory contains reusable modules and environment definitions used to provision the KorA
Semantics platform on AWS.

## Modules
- `modules/network` provisions a VPC, public/private subnets, routing, NAT gateway, and security
  groups that separate control-plane and data-plane traffic.
- `modules/eks` provisions an Amazon EKS cluster, IAM roles, managed node groups, and an
  OIDC provider for IRSA integrations.
- `modules/s3_bucket` creates opinionated S3 buckets with encryption, lifecycle management, and
  configurable public access controls.
- `modules/efs` builds an encrypted Amazon EFS file system with security-group scoped access and
  optional AWS Backup integration.
- `modules/metadata_db` provisions the Aurora PostgreSQL metadata database along with subnet and
  security groups plus a Secrets Manager secret (and optional rotation wiring).
- `modules/parameter_outputs` publishes selected environment outputs into SSM Parameter Store so
  other stacks and services can discover them programmatically.

Modules are designed to accept tags and generalized inputs so they can be reused for additional
environments or cloned to other cloud providers in the future.

## Environments
- `envs/dev` configures a cost-optimized development environment with smaller instance types, a
  spot-backed workload node group, force-destroy S3 buckets, a single `db.t4g.medium` metadata
  instance, and disabled secret rotation by default.
- `envs/staging` mirrors production capacity with dedicated analytics node pools, multi-AZ EFS and
  Aurora capacity, stricter backup/retention policies, and Parameter Store publishing under the
  staging namespace.

Both environments expose variables for encryption keys, backup retention, secret rotation, and
parameter store prefixes via their respective `variables.tf` files. Adjust these defaults as needed
when promoting configuration to additional stages.

Each environment expects remote state configuration to be passed during `terraform init`.
Use the GitHub Actions workflow or run the commands locally as described in the repository README.
