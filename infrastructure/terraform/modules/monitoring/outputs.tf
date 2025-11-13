output "sns_topic_arn" {
  description = "ARN of the SNS topic receiving monitoring alerts"
  value       = aws_sns_topic.alarms.arn
}

output "flow_log_group_name" {
  description = "Name of the CloudWatch log group receiving VPC flow logs"
  value       = aws_cloudwatch_log_group.vpc_flow.name
}
