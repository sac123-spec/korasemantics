resource "aws_cloudwatch_log_group" "vpc_flow" {
  name              = "/aws/vpc/${var.name}/flow-logs"
  retention_in_days = var.flow_log_retention_in_days

  tags = merge(var.tags, {
    Name = "${var.name}-vpc-flow-logs"
  })
}

resource "aws_iam_role" "flow_logs" {
  name = "${var.name}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name}-flow-logs-role"
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "${var.name}-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "vpc" {
  log_destination      = aws_cloudwatch_log_group.vpc_flow.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = var.vpc_id
  iam_role_arn         = aws_iam_role.flow_logs.arn

  tags = merge(var.tags, {
    Name = "${var.name}-vpc-flow-log"
  })
}

resource "aws_sns_topic" "alarms" {
  name = "${var.name}-monitoring-alarms"

  tags = merge(var.tags, {
    Name = "${var.name}-monitoring-alarms"
  })
}

resource "aws_sns_topic_subscription" "email" {
  for_each = { for address in var.notification_emails : address => address }

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_cloudwatch_metric_alarm" "eks_failed_nodes" {
  alarm_name          = "${var.name}-eks-failed-nodes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "ClusterFailedNodeCount"
  namespace           = "AWS/EKS"
  period              = var.alarm_period
  statistic           = "Maximum"
  threshold           = var.alarm_threshold
  treat_missing_data  = "breaching"
  alarm_description   = "Alert when the EKS cluster reports failed nodes."

  dimensions = {
    ClusterName = var.eks_cluster_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

resource "aws_xray_sampling_rule" "default" {
  rule_name      = "${var.name}-default"
  priority       = 10000
  version        = 1
  reservoir_size = 1
  fixed_rate     = var.xray_fixed_rate

  url_path      = "*"
  http_method   = "*"
  service_type  = "*"
  service_name  = "${var.name}-service"
  resource_arn  = "*"
  host          = "*"
  attributes    = {}
}
