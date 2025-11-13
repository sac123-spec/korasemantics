# Terraform Infrastructure

This directory contains reusable modules and environment definitions used to provision the KorA
Semantics platform on AWS.

## Modules
- `modules/network` provisions a VPC, public/private subnets, routing, NAT gateway, and security
groups that separate control-plane and data-plane traffic.
- `modules/eks` provisions an Amazon EKS cluster, IAM roles, managed node groups, and an
  OIDC provider for IRSA integrations.

Modules are designed to accept tags and generalized inputs so they can be reused for additional
environments or cloned to other cloud providers in the future.

## Environments
- `envs/dev` configures a cost-optimized development environment with smaller instance types and a
  spot-backed workload node group.
- `envs/staging` mirrors production capacity with dedicated analytics node pools and stricter
  scaling parameters.

Each environment expects remote state configuration to be passed during `terraform init`.
Use the GitHub Actions workflow or run the commands locally as described in the repository README.
