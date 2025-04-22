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