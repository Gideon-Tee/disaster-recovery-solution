output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.app_alb.dns_name
}

output "primary_alb_arn" {
  description = "ARN of ALB in primary region"
  value = aws_lb.app_alb.arn
}

output "dr_alb_arn" {
  description = "ARN of ALB in dr region"
  value = aws_lb.dr-app_alb.arn
}

output "dr_alb_dns_name" {
  description = "DNS name of the DR ALB"
  value       = aws_lb.dr-app_alb.dns_name
}

output "primary_alb_arn_suffix" {
  description = "ARN suffix of the primary ALB"
  value = aws_lb.app_alb.arn_suffix
}

output "primary_target_group_arn_suffix" {
  description = "ARN suffix of the primary ALB target group"
  value = aws_lb_target_group.app_tg.arn_suffix
}

output "target_group_arn" {
  description = "ARN of the target group (for ASG attachment)"
  value       = aws_lb_target_group.app_tg.arn
}
output "dr_target_group_arn" {
  description = "ARN of the target group (for ASG attachment)"
  value       = aws_lb_target_group.dr_app_tg.arn
}

output "load_balancer_sg_id" {
  value = aws_lb.app_alb.security_groups
}
output "dr_load_balancer_sg_id" {
  value = aws_lb.dr-app_alb.security_groups
}