variable "region" {
  description = "AWS region for networking resources"
  type        = string
}

variable "dr_region" {
  description = "AWS region for networking resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "12.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["12.0.1.0/24", "12.0.10.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["12.0.3.0/24", "12.0.5.0/24"]
}

variable "environment" {
  description = "Environment tag (primary/dr)"
  type        = string
}

variable "key_name" {
  description = "Key pair for ssh"
  type        = string
  default     = "sandbox_ssh"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appDB"
}

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "account_id" {}