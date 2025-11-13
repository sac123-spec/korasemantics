output "config_bucket_name" {
  description = "Name of the bucket receiving AWS Config snapshots"
  value       = local.config_bucket_name
}

output "guardduty_detector_id" {
  description = "Identifier of the enabled GuardDuty detector"
  value       = aws_guardduty_detector.this.id
}
