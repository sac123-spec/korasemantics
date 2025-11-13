# Cloud Platform Strategy

## Cloud Provider Selection
- **Primary Provider: Amazon Web Services (AWS)**
  - Global footprint with mature managed Kubernetes (EKS) and analytics services.
  - Native integrations with IAM, Security Hub, and GuardDuty simplify security baselines.
  - Rich ecosystem of third-party tooling and marketplace AMIs for data workloads.
- **Secondary/Contingency Provider: Google Cloud Platform (GCP)**
  - Optional data analytics workloads can burst into GKE/BigQuery if latency or regional requirements demand.
  - Templates mirror the AWS design to ease portability.

## Service Mapping
| Capability | AWS Services | Purpose |
| --- | --- | --- |
| Object Storage | S3 with S3 Glacier tiers | Durable storage for metadata, ML artifacts, and backups. |
| Block Storage | EBS (gp3) | Persistent volumes for stateful workloads in the data plane. |
| Shared File Storage | EFS | POSIX-compliant storage for shared datasets and feature stores. |
| Databases | Amazon RDS (PostgreSQL) / Aurora Serverless | Metadata, control plane configuration, and transactional workloads. |
| Networking Core | VPC, Private/Public Subnets, NAT Gateway, Transit Gateway (optional) | Segmented networking with isolated control/data plane subnets and egress. |
| Ingress | Application Load Balancer (ALB) / NLB for gRPC | Terminate TLS and distribute requests to control plane services. |
| Service Mesh (optional) | AWS App Mesh or Istio on EKS | Zero-trust communication between microservices. |
| Secrets & Keys | AWS Secrets Manager, KMS (CMKs) | Secrets rotation and envelope encryption for data at rest and in transit. |
| Monitoring | CloudWatch, AWS X-Ray, CloudTrail | Observability for platform health, tracing, and audit logs. |
| Security Baseline | AWS IAM, GuardDuty, Security Hub, Config | Identity management, threat detection, and continuous compliance. |
| CI/CD Integrations | GitHub Actions OIDC -> AWS IAM | Short-lived credentials for automation without static secrets. |

## Control Plane vs Data Plane
- **Control Plane**
  - **Responsibilities**: API gateway, authentication and authorization, metadata services, orchestration components, centralized logging, and metrics aggregation.
  - **Resources**: EKS control-plane namespace, RDS metadata database, Redis/ElastiCache for coordination, ALB for ingress, PrivateLink or API Gateway for external integrations.
  - **Security**: Restrictive security groups, AWS WAF on ingress ALB, IAM roles with least privilege, audit trails via CloudTrail and Config rules.

- **Data Plane**
  - **Responsibilities**: User compute (Kubernetes workloads, EMR/Glue jobs, Spark-on-K8s), object and block storage access, feature engineering pipelines, batch processing.
  - **Resources**: Dedicated EKS node groups with autoscaling, managed spot node groups for cost optimization, S3 buckets, EFS mounts, and per-tenant namespaces.
  - **Security**: Separate VPC subnets and security groups, IAM roles for service accounts (IRSA) with scoped access to S3/EFS, network policies to restrict east-west traffic.

## Environment Strategy
- **Shared Development**: Dev environment mirrors production topology with smaller node sizes. Terraform workspaces provision isolated VPC CIDRs (e.g., /20 blocks) and use EKS managed node groups for quick iteration.
- **Staging**: Blue/green deployments validated against production-like data plane capacity. Enables canary releases before promoting to production.
- **Production**: Follows staged rollouts from staging; includes multi-AZ deployment, cross-account isolation, and stricter IAM guardrails (service control policies).

## Security & Compliance Baseline
1. Enforce AWS Organizations SCPs to disable risky services.
2. Centralize logging (CloudTrail, VPC Flow Logs, Kubernetes audit logs) into a dedicated log archive account.
3. Deploy GuardDuty, Security Hub, and AWS Config conformance packs via Terraform.
4. Use KMS CMKs with automatic key rotation; enforce TLS 1.2+ for all ingress endpoints.
5. Integrate IAM Access Analyzer and AWS SSO for workforce identity federation.

## Disaster Recovery & Resilience
- Multi-AZ clusters and database replicas.
- Nightly automated snapshots (S3 lifecycle policies, RDS snapshots) replicated to secondary region (us-west-2) for cold-standby recovery.
- Run periodic game days validated via Infrastructure-as-Code pipelines.

## Portability Considerations
- Use Kubernetes manifests and Helm charts portable between AWS EKS and GCP GKE.
- Abstract storage access through S3-compatible APIs (MinIO for local testing) to ease migration.
- Maintain Terraform modules with provider-agnostic variables to support future multi-cloud expansion.
