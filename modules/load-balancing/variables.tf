variable "vpc_id" {
  description = "VPC ID where ALB will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "dr_vpc_id" {
  description = "VPC ID where DR ALB will be deployed"
  type        = string
}

variable "dr_subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}


variable "dr_security_group_ids" {
  description = "Security group IDs for ALB"
  type        = list(string)
}

variable "environment" {
  description = "Environment (primary/dr)"
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs for ALB"
  type        = list(string)
}