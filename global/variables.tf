variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "dr_region" {
  description = "Disaster recovery AWS region"
  type        = string
  default     = "us-east-1"
}

variable "primary_alb_arn" {
  description = "ARN of the primary ALB"
  type        = string
}

variable "dr_alb_arn" {
  description = "ARN of the DR ALB"
  type        = string
}