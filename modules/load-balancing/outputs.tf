output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.app_alb.dns_name
}

output "target_group_arn" {
  description = "ARN of the target group (for ASG attachment)"
  value       = aws_lb_target_group.app_tg.arn
}

output "load_balancer_sg_id" {
  value = aws_lb.app_alb.security_groups
}