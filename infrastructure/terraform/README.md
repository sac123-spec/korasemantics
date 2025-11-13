# Terraform Infrastructure

This directory contains reusable modules and environment definitions used to provision the KorA
Semantics platform on AWS.

## Modules
- `modules/network` provisions a VPC, public/private subnets, routing, NAT gateway, and security
  groups that separate control-plane and data-plane traffic. Control plane ingress is
  parameterized through the `control_plane_ingress_cidrs` variable so environments can restrict
  access to approved networks.
- `modules/eks` provisions an Amazon EKS cluster, IAM roles, managed node groups, and an
  OIDC provider for IRSA integrations. Control plane logging is enabled by default with
  a 30-day retention period that can be overridden per environment.
- `modules/monitoring` enables VPC flow logs, an Amazon CloudWatch alarm that monitors the
  EKS cluster's failed node count, an SNS topic for alerting, and a baseline AWS X-Ray
  sampling rule.
- `modules/logging` provisions an organization-level, multi-region CloudTrail that writes to an
  encrypted S3 archive, optionally streams events to CloudWatch Logs, and prepares IRSA
  permissions so Fluent Bit can forward EKS audit records into the centralized log stores.
- `modules/security` enables GuardDuty, Security Hub (with configurable standards), and
  configures AWS Config to deploy a conformance pack that validates EKS logging and
  GuardDuty enablement. The module also provisions or connects to an S3 bucket for
  Config snapshots.

Modules are designed to accept tags and generalized inputs so they can be reused for additional
environments or cloned to other cloud providers in the future.

## Environments
- `envs/dev` configures a cost-optimized development environment with smaller instance types and a
  spot-backed workload node group.
- `envs/staging` mirrors production capacity with dedicated analytics node pools and stricter
  scaling parameters.

Each environment expects remote state configuration to be passed during `terraform init`.
Use the GitHub Actions workflow or run the commands locally as described in the repository README.

### Configuring control plane access

Provide CIDR lists for the control plane API by updating `control_plane_ingress_cidrs` in each
environment's `variables.tf`. For example, the development environment defaults to the VPC CIDR in
`envs/dev/variables.tf`, while staging tightens access through the values in
`envs/staging/variables.tf`. Override these defaults using a `*.tfvars` file or `-var` flags during
`terraform apply` to match the network ranges for your deployment.
