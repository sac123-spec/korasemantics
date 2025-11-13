# KorA Semantics Platform Infrastructure

This repository captures the infrastructure strategy and automation for the KorA Semantics platform.
It includes architecture decisions, Terraform modules for AWS networking and compute, and a CI/CD
workflow that provisions shared development and staging environments automatically.

## Repository Layout
- `docs/cloud-architecture.md` &mdash; Cloud platform decisions, service mapping, and control/data plane
  responsibilities.
- `infrastructure/terraform/modules` &mdash; Reusable Terraform modules for the network and Amazon EKS.
- `infrastructure/terraform/envs` &mdash; Environment-specific Terraform configurations (development and staging).
- `.github/workflows/provision.yml` &mdash; GitHub Actions workflow to execute Terraform against shared environments.

## Getting Started
1. Install Terraform 1.5+ and configure AWS credentials with sufficient permissions.
2. For each environment (e.g., `dev`), initialize Terraform with backend configuration:

   ```bash
   cd infrastructure/terraform/envs/dev
   terraform init \
     -backend-config="bucket=<state-bucket>" \
     -backend-config="dynamodb_table=<lock-table>" \
     -backend-config="key=korasemantics-dev.tfstate" \
     -backend-config="region=<aws-region>"
   terraform plan
   ```

3. Apply the plan once reviewed:

   ```bash
   terraform apply
   ```

## CI/CD Workflow
The `Provision Shared Environments` workflow runs on pushes to `main` or manually via the GitHub UI.
It expects the following repository secrets/variables:

| Name | Type | Purpose |
| --- | --- | --- |
| `AWS_IAC_ROLE_ARN` | Secret | IAM role assumed via GitHub OIDC for Terraform automation. |
| `TF_STATE_BUCKET` | Secret | S3 bucket that stores Terraform remote state. |
| `TF_STATE_LOCK_TABLE` | Secret | DynamoDB table for Terraform state locking. |
| `AWS_REGION` | Repository variable | Default AWS region for automation (overrides module defaults). |

Terraform runs `terraform fmt`, `plan`, and `apply` (on `main`) for both `dev` and `staging`
environments using a build matrix.
