data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

locals {
  normalized_name        = replace(lower(var.name), "[^a-z0-9-]", "")
  bucket_name            = coalesce(var.log_bucket_name, "${local.normalized_name}-log-archive")
  cloudtrail_trail_name  = coalesce(var.trail_name, "${local.normalized_name}-org-trail")
  cloudtrail_log_group   = var.enable_cloudwatch_logs ? coalesce(var.cloudtrail_log_group_name, "/aws/cloudtrail/${var.name}") : null
  eks_audit_log_group    = var.enable_eks_audit_log_shipping ? (var.create_dedicated_audit_log_group ? coalesce(var.eks_audit_log_group_name, "/aws/eks/${var.name}/audit") : local.cloudtrail_log_group) : null
  oidc_provider_path     = var.eks_oidc_provider_arn != null ? element(split("oidc-provider/", var.eks_oidc_provider_arn), 1) : null
}

data "aws_iam_policy_document" "kms" {
  statement {
    sid     = "AllowRootAccountAdministration"
    effect  = "Allow"
    actions = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudTrailEncrypt"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudWatchLogsEncrypt"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }

    actions = [
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*"
    ]

    resources = ["*"]
  }
}

resource "aws_kms_key" "log_archive" {
  description             = "KMS key for ${var.name} log archive"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = true
  multi_region            = true
  policy                  = data.aws_iam_policy_document.kms.json

  tags = merge(var.tags, {
    Name = "${var.name}-log-archive"
  })
}

resource "aws_kms_alias" "log_archive" {
  name          = "alias/${local.normalized_name}-log-archive"
  target_key_id = aws_kms_key.log_archive.id
}

resource "aws_s3_bucket" "log_archive" {
  bucket        = local.bucket_name
  force_destroy = var.log_bucket_force_destroy

  tags = merge(var.tags, {
    Name = "${var.name}-log-archive"
  })
}

resource "aws_s3_bucket_versioning" "log_archive" {
  bucket = aws_s3_bucket.log_archive.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_archive" {
  bucket = aws_s3_bucket.log_archive.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.log_archive.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "log_archive" {
  bucket = aws_s3_bucket.log_archive.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "log_archive" {
  bucket = aws_s3_bucket.log_archive.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

data "aws_iam_policy_document" "log_bucket" {
  statement {
    sid    = "AllowCloudTrailAccessCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl", "s3:ListBucket"]
    resources = [aws_s3_bucket.log_archive.arn]
  }

  statement {
    sid    = "AllowCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.log_archive.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
      "${aws_s3_bucket.log_archive.arn}/AWSLogs/${var.organization_id}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "log_archive" {
  bucket = aws_s3_bucket.log_archive.id
  policy = data.aws_iam_policy_document.log_bucket.json
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name              = local.cloudtrail_log_group
  kms_key_id        = aws_kms_key.log_archive.arn
  retention_in_days = var.cloudtrail_log_retention_in_days

  tags = merge(var.tags, {
    Name = "${var.name}-cloudtrail"
  })
}

resource "aws_iam_role" "cloudtrail" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name = "${var.name}-cloudtrail-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name}-cloudtrail-logs"
  })
}

resource "aws_iam_role_policy" "cloudtrail" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name = "${var.name}-cloudtrail-logs"
  role = aws_iam_role.cloudtrail[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Resource = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "eks_audit" {
  count = var.enable_eks_audit_log_shipping && var.create_dedicated_audit_log_group ? 1 : 0

  name              = local.eks_audit_log_group
  kms_key_id        = aws_kms_key.log_archive.arn
  retention_in_days = var.eks_audit_log_retention_in_days

  tags = merge(var.tags, {
    Name = "${var.name}-eks-audit"
  })
}

locals {
  cloudtrail_log_group_arn = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.cloudtrail[0].arn : null
  audit_log_group_name     = local.eks_audit_log_group
  audit_log_group_arn = var.enable_eks_audit_log_shipping ? (
    var.create_dedicated_audit_log_group ? aws_cloudwatch_log_group.eks_audit[0].arn : local.cloudtrail_log_group_arn
  ) : null
}

resource "aws_iam_role" "eks_audit" {
  count = var.enable_eks_audit_log_shipping && var.create_eks_audit_irsa_role ? 1 : 0

  name = "${var.name}-eks-audit"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = var.eks_oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${local.oidc_provider_path}:sub" = "system:serviceaccount:${var.eks_audit_service_account_namespace}:${var.eks_audit_service_account_name}"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name}-eks-audit"
  })

  lifecycle {
    precondition {
      condition     = var.eks_oidc_provider_arn != null
      error_message = "An EKS OIDC provider ARN must be supplied when creating the audit shipper IRSA role."
    }
  }
}

resource "aws_iam_policy" "eks_audit" {
  count = var.enable_eks_audit_log_shipping && var.create_eks_audit_irsa_role ? 1 : 0

  name = "${var.name}-eks-audit"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:DescribeLogStreams",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "${local.audit_log_group_arn}:*"
      },
      {
        Effect = "Allow",
        Action = [
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
        ],
        Resource = aws_kms_key.log_archive.arn
      }
    ]
  })

  lifecycle {
    precondition {
      condition     = local.audit_log_group_arn != null
      error_message = "A CloudWatch Logs destination must be available before creating the EKS audit shipper policy."
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_audit" {
  count = var.enable_eks_audit_log_shipping && var.create_eks_audit_irsa_role ? 1 : 0

  role       = aws_iam_role.eks_audit[0].name
  policy_arn = aws_iam_policy.eks_audit[0].arn
}

resource "aws_cloudtrail" "organization" {
  name                          = local.cloudtrail_trail_name
  s3_bucket_name                = aws_s3_bucket.log_archive.id
  kms_key_id                    = aws_kms_key.log_archive.arn
  is_multi_region_trail         = true
  is_organization_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  dynamic "insight_selector" {
    for_each = var.cloudtrail_insight_selectors

    content {
      insight_type = insight_selector.value.insight_type
    }
  }

  dynamic "event_selector" {
    for_each = [
      {
        read_write_type           = "All",
        include_management_events = true
      }
    ]

    content {
      read_write_type           = event_selector.value.read_write_type
      include_management_events = event_selector.value.include_management_events
    }
  }

  cloud_watch_logs_group_arn = var.enable_cloudwatch_logs ? "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*" : null
  cloud_watch_logs_role_arn  = var.enable_cloudwatch_logs ? aws_iam_role.cloudtrail[0].arn : null

  depends_on = [
    aws_s3_bucket_policy.log_archive
  ]

  lifecycle {
    precondition {
      condition = (
        var.enable_eks_audit_log_shipping == false ||
        var.create_dedicated_audit_log_group ||
        var.enable_cloudwatch_logs
      )
      error_message = "EKS audit log shipping requires either CloudTrail CloudWatch delivery or a dedicated audit log group."
    }
  }
}
