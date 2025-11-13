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

## Frontend Dashboard
The repository now includes a TypeScript React dashboard under `ui/` that reads Terraform configuration to
visualize environment modules.

### Install Dependencies
```bash
cd ui
npm install
```

### Run Locally
```bash
npm run dev
```
Vite runs the application on http://localhost:5173 by default. The dashboard loads Terraform module metadata at
build time, so no additional backend is required for local development.

### Connecting to Live Environment Data
The dashboard currently mocks AWS runtime status responses. Once real APIs are available you can replace the
mock adapter in `src/lib/adapters/mockAwsStatus.ts` with calls to your service (REST, GraphQL, etc.). When doing so:
1. Expose an endpoint that aggregates module health by environment ID.
2. Replace `getMockModuleStatus` with a fetch-based implementation that requests your endpoint.
3. Ensure the API includes CORS headers so the Vite dev server (and production host) can reach it.
4. Add environment variables (e.g., via Vite `.env` files) to point to the correct API base URL per environment.

Because Terraform configuration is already bundled using `import.meta.glob`, the UI will automatically surface
new environments or modules added under `infrastructure/terraform` without additional code changes.
