output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public_subnets[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private_subnets[*].id
}

output "dr_private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.dr-private_subnets[*].id
}

output "dr_public_subnet_ids" {
  value = aws_subnet.dr-public_subnets[*].id
}

output "alb_security_group_id" {
  value = aws_security_group.alb_sg.id
}

output "dr_alb_security_group_id" {
  value = aws_security_group.dr-alb_sg.id
}

output "dr_vpc_id" {
  value = aws_vpc.dr_vpc.id
}