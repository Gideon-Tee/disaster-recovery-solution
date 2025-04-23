output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app_asg.name
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.app_lt.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.app_sg.id
}

output "primary_instance_id" {
  value = data.aws_instance.app_instance.id
}

output "dr_asg_name" {
  description = "Name of the DR ASG"
  value       = aws_autoscaling_group.dr-app_asg.name
}
