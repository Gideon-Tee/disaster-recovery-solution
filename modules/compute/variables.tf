variable "environment" {
  description = "Environment (primary/dr)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ASG"
  type        = list(string)
}

variable "dr-subnet_ids" {
  description = "List of subnet IDs for ASG"
  type        = list(string)
}

variable "ami_id" {
  description = "AMI ID for instances (defaults to latest Ubuntu 22.04 LTS)"
  type        = string
  default     = null  # Will use SSM Parameter lookup if null
}

variable "dr_ami_id" {
  description = "AMI created from the primary running instance by SSM"
  type        = string
  default     = "ami-084568db4383264d4"  # Will use SSM Parameter lookup if null
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "sandbox_ssh.pem"
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 2
}

variable "target_group_arns" {
  description = "ARNs of target groups to attach to the ASG"
  type        = list(string)
  default     = []
}

variable "dr-target_group_arns" {
  description = "ARNs of target groups to attach to the ASG"
  type        = list(string)
}

variable "iam_instance_profile_arn" {
  type = string
}

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {}
variable "dr_region" {default = "us-east-1"}
variable "s3_bucket_name" {}
variable "db_username" {}
variable "db_password" {}
variable "db_host" {}
variable "db_name" {}
variable "load_balancer_sg_id" {}
variable "dr_s3_bucket_name" {}
variable "dr_db_host" {}

variable "dr_vpc_id" {
  description = "DR region VPC id"
}

variable "dr_load_balancer_sg_id" {}