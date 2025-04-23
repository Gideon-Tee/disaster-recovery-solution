output "latest_ami_id" {
  value = aws_ssm_document.create_ami.content
}

output "primary_alb_alarm_arn" {
  description = "ARN of the CloudWatch alarm for primary ALB"
  value       = aws_cloudwatch_metric_alarm.primary_alb_healthy_hosts.arn
}

output "primary_rds_alarm_arn" {
  description = "ARN of the CloudWatch alarm for primary RDS"
  value       = aws_cloudwatch_metric_alarm.primary_rds_cpu.arn
}