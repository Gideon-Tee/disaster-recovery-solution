variable "primary_region" {
  description = "Primary AWS region"
  default = "eu-west-1"
}

variable "dr_region" {
  description = "Disaster recovery region"
  type = string
  default = "us-east-1"
}

variable "primary_instance_id" {
  description = "ID of the primary EC2 instance to create AMI from"
  type = string
}

variable "primary_alb_arn_suffix" {
  description = "ARN suffix of the primary ALB (e.g., app/my-alb/1234567890)"
  type        = string
}

variable "primary_target_group_arn_suffix" {
  description = "ARN suffix of the primary ALB target group (e.g., targetgroup/my-tg/1234567890)"
  type        = string
}

variable "primary_rds_identifier" {
  description = "Identifier of the primary RDS instance"
  type        = string
}

variable "dr_rds_identifier" {}
variable "dr_asg_name" {}
variable "dr_s3_bucket_name" {}

variable "account_id" {}