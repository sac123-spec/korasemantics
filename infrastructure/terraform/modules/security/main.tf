data "aws_partition" "current" {}

data "aws_region" "current" {}

locals {
  securityhub_standard_arns = [
    for identifier in var.securityhub_enabled_standards :
    "arn:${data.aws_partition.current.partition}:securityhub:${data.aws_region.current.name}::standards/${identifier}"
  ]

  managed_config_bucket_name = try(aws_s3_bucket.config[0].bucket, null)
  managed_config_bucket_arn  = try(aws_s3_bucket.config[0].arn, null)
  config_bucket_name         = coalesce(var.config_logs_bucket_name, local.managed_config_bucket_name)
}

resource "aws_guardduty_detector" "this" {
  enable                       = true
  finding_publishing_frequency = var.guardduty_finding_publishing_frequency

  tags = merge(var.tags, {
    Name = "${var.name}-guardduty"
  })
}

resource "aws_securityhub_account" "this" {
  enable_default_standards = false
}

resource "aws_securityhub_standards_subscription" "this" {
  for_each = { for arn in local.securityhub_standard_arns : arn => arn }

  standards_arn = each.value
}

resource "aws_s3_bucket" "config" {
  count = var.config_logs_bucket_name == null ? 1 : 0

  bucket_prefix = "${replace(lower(var.name), "[^a-z0-9-]", "")}-config-"
  force_destroy = var.config_bucket_force_destroy

  tags = merge(var.tags, {
    Name = "${var.name}-config-logs"
  })
}

resource "aws_s3_bucket_versioning" "config" {
  count  = var.config_logs_bucket_name == null ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  count  = var.config_logs_bucket_name == null ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "config" {
  name = "${var.name}-aws-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name}-aws-config-role"
  })
}

resource "aws_iam_role_policy_attachment" "config" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSConfigRole"
  role       = aws_iam_role.config.name
}

resource "aws_s3_bucket_policy" "config" {
  count  = var.config_logs_bucket_name == null ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl",
          "s3:ListBucket"
        ],
        Resource = [
          local.managed_config_bucket_arn,
          "${local.managed_config_bucket_arn}/*"
        ],
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_config_configuration_recorder" "this" {
  name     = "${var.name}-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  name           = "${var.name}-delivery"
  s3_bucket_name = local.config_bucket_name

  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}

resource "aws_config_conformance_pack" "this" {
  name = var.conformance_pack_name

  template_body = templatefile("${path.module}/templates/conformance-pack.yaml", {
    EKSClusterNames = var.eks_cluster_name
  })

  depends_on = [aws_config_configuration_recorder_status.this]
}
