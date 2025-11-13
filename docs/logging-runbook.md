# Centralized Logging Runbook

This runbook explains how to locate, retain, and forward the aggregated audit
and activity logs that are provisioned by the `modules/logging` Terraform
module.

## CloudTrail

- **Trail scope:** A single organization-level, multi-region CloudTrail is
  deployed. It captures management events across every account in the AWS
  Organization and stores log files in the encrypted S3 archive bucket.
- **S3 storage:** The log archive bucket name is exposed as the
  `log_bucket_name` output from the logging module. By default the bucket is
  created automatically and encrypted with a dedicated multi-Region KMS key.
- **Retention:** S3 versioning and KMS encryption are enforced. Lifecycle
  policies are intentionally left unmanaged so that retention can be governed by
  organization policy; configure them through a follow-up Terraform change if
  time-bound retention is required.
- **CloudWatch streaming:** When `logging_enable_cloudwatch_logs` is enabled
  (default), CloudTrail also streams to the centralized CloudWatch Logs group.
  Use the `cloudtrail_log_group_name` output to find the group and build metric
  filters or Insights queries.

## EKS control-plane audit logs

- **Collection options:** The logging module can reuse the CloudTrail log group
  or create a dedicated group by toggling
  `logging_create_dedicated_audit_log_group`. The selected destination is
  exposed through the `eks_audit_log_group_name` output.
- **Fluent Bit / IRSA permissions:** When
  `logging_enable_eks_audit_irsa_role` is true (default), the module provisions
  an IAM role bound to the cluster's OIDC provider. Annotate the Fluent Bit
  DaemonSet's service account with the emitted `eks_audit_role_arn` and configure
  the output plugin to write into the audit log group.
- **Retention:** The audit log group's retention is controlled by
  `logging_eks_audit_log_retention_in_days`. Update the environment variable if a
  different retention period is required.

## Access controls

- **S3 access:** Bucket policies restrict writes to the CloudTrail service and
  AWS Organizations delivery paths. Grant read access to security analysts by
  creating IAM policies that reference the `log_bucket_arn` output.
- **KMS usage:** The KMS key ID is exported via `kms_key_id`. Any principal that
  needs to decrypt log files must be granted access through KMS key policies or
  IAM grants.

## Operational tasks

1. **Onboarding a new environment:** Ensure the environment stack passes the
   correct `organization_id` and, if applicable, overrides for retention and
   bucket naming. Apply Terraform to deploy the logging baseline before enabling
   workload traffic.
2. **Investigating incidents:** Pull CloudTrail events from the centralized log
   group (CloudWatch) for recent activity, or query the S3 bucket for historical
   evidence. For cluster-specific investigations, start with the EKS audit log
   group to review Kubernetes API calls.
3. **Long-term retention:** Export CloudWatch log groups to S3 or Glacier using
   subscription filters or AWS Backup if regulatory requirements exceed the
   configured retention windows.

Refer to the environment-specific Terraform outputs for the exact resource
names once the stacks have been applied.
