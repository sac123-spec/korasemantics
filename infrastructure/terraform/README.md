# Terraform Infrastructure

This directory contains reusable modules and environment definitions used to provision the KorA
Semantics platform on AWS.

## Modules
- `modules/network` provisions a VPC, public/private subnets, routing, NAT gateway, and security
groups that separate control-plane and data-plane traffic.
- `modules/eks` provisions an Amazon EKS cluster, IAM roles, managed node groups, and an
  OIDC provider for IRSA integrations. Control plane logging is enabled by default with
  a 30-day retention period that can be overridden per environment.
- `modules/monitoring` enables VPC flow logs, an Amazon CloudWatch alarm that monitors the
  EKS cluster's failed node count, an SNS topic for alerting, and a baseline AWS X-Ray
  sampling rule.
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

### Monitoring and security configuration

Both `envs/dev` and `envs/staging` expose variables that tune log retention, alarm
thresholds, and notification channels. Update the corresponding `variables.tf` or
provide a `terraform.tfvars` file to override the defaults listed below:

| Variable | Dev default | Staging default | Description |
| --- | --- | --- | --- |
| `cluster_log_retention_in_days` | `30` | `90` | CloudWatch retention for EKS control plane logs. |
| `monitoring_flow_log_retention_in_days` | `90` | `120` | CloudWatch retention for VPC flow logs. |
| `monitoring_alarm_period` | `300` | `300` | Evaluation period (seconds) for the failed node alarm. |
| `monitoring_alarm_evaluation_periods` | `1` | `2` | Number of periods that must breach before alarming. |
| `monitoring_alarm_threshold` | `1` | `1` | Failed node count threshold that triggers the alarm. |
| `monitoring_notification_emails` | `[]` | `[]` | Email addresses subscribed to the SNS topic. |
| `monitoring_xray_fixed_rate` | `0.05` | `0.1` | Default AWS X-Ray sampling rate for traces. |
| `security_guardduty_finding_publishing_frequency` | `"SIX_HOURS"` | `"FIFTEEN_MINUTES"` | GuardDuty finding export cadence. |
| `securityhub_enabled_standards` | `["aws-foundational-security-best-practices/v/1.0.0"]` | `["aws-foundational-security-best-practices/v/1.0.0", "cis-aws-foundations-benchmark/v/1.4.0"]` | Security Hub standards subscribed. |
| `security_config_logs_bucket_name` | `null` | `null` | Provide an existing bucket to reuse for AWS Config snapshots. |
| `security_conformance_pack_name` | `"korasemantics-dev-baseline"` | `"korasemantics-staging-baseline"` | Name for the deployed conformance pack. |

When `security_config_logs_bucket_name` is omitted the security module creates a dedicated
bucket with blocking public access and versioning enabled. Email subscriptions to the
monitoring SNS topic require manual confirmation by each recipient.
