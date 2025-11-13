locals {
  instance_indexes = { for idx in range(var.instance_count) : idx => idx }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name}-subnet-group"
  })
}

resource "aws_security_group" "this" {
  name        = "${var.name}-db"
  description = "Metadata database security group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-db"
  })
}

resource "aws_security_group_rule" "ingress_security_groups" {
  for_each = toset(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = each.value
  description              = "Allow database access from security group"
}

resource "aws_security_group_rule" "ingress_cidrs" {
  for_each = toset(var.allowed_cidr_blocks)

  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  cidr_blocks       = [each.value]
  description       = "Allow database access from CIDR"
}

resource "random_password" "master" {
  length  = 24
  special = true
}

resource "aws_secretsmanager_secret" "this" {
  name       = "${var.name}-credentials"
  kms_key_id = var.secret_kms_key_id

  tags = merge(var.tags, {
    Name = "${var.name}-credentials"
  })
}

resource "aws_rds_cluster" "this" {
  cluster_identifier              = var.name
  engine                          = var.engine
  engine_version                  = var.engine_version
  master_username                 = var.master_username
  master_password                 = random_password.master.result
  database_name                   = var.db_name
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = [aws_security_group.this.id]
  storage_encrypted               = var.storage_encrypted
  kms_key_id                      = var.kms_key_id
  deletion_protection             = var.deletion_protection
  skip_final_snapshot             = var.skip_final_snapshot
  apply_immediately               = var.apply_immediately
  port                            = var.port
  copy_tags_to_snapshot           = true
  iam_database_authentication_enabled = false

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_rds_cluster_instance" "this" {
  for_each = local.instance_indexes

  identifier         = "${var.name}-${each.key + 1}"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.instance_class
  engine             = var.engine
  engine_version     = var.engine_version
  publicly_accessible = false

  tags = merge(var.tags, {
    Name = "${var.name}-${each.key + 1}"
  })
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
    engine   = var.engine
    host     = aws_rds_cluster.this.endpoint
    port     = var.port
    dbname   = var.db_name
  })

  depends_on = [aws_rds_cluster.this]
}

resource "aws_secretsmanager_secret_rotation" "this" {
  count               = var.enable_secret_rotation && var.rotation_lambda_arn != null ? 1 : 0
  secret_id           = aws_secretsmanager_secret.this.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}
