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

data "aws_caller_identity" "current" {}  # Used for S3 bucket naming