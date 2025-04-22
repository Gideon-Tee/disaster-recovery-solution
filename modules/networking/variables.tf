variable "region" {
  description = "AWS region for networking resources"
  type        = string
}

variable "dr_region" {
  description = "AWS region for DR"
  type = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "12.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "environment" {
  description = "Environment tag (primary/dr)"
  type        = string
}

