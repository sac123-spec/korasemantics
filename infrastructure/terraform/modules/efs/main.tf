resource "aws_security_group" "efs" {
  name        = "${var.name}-efs"
  description = "EFS security group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-efs"
  })
}

resource "aws_security_group_rule" "ingress_security_groups" {
  for_each = toset(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.efs.id
  source_security_group_id = each.value
  description              = "Allow NFS from allowed security group"
}

resource "aws_security_group_rule" "ingress_cidrs" {
  for_each = toset(var.allowed_cidr_blocks)

  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  security_group_id = aws_security_group.efs.id
  cidr_blocks       = [each.value]
  description       = "Allow NFS from CIDR"
}

resource "aws_efs_file_system" "this" {
  creation_token  = var.name
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode
  encrypted        = var.encrypted
  kms_key_id       = var.kms_key_id

  provisioned_throughput_in_mibps = var.throughput_mode == "provisioned" ? var.provisioned_throughput_in_mibps : null

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_efs_backup_policy" "this" {
  count = var.backup_policy_enabled ? 1 : 0

  file_system_id = aws_efs_file_system.this.id

  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_efs_mount_target" "this" {
  for_each = toset(var.subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}
