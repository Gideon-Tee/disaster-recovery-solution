variable "environment" {
  description = "Environment for deployment"
  type = string
}

variable "ec2_role_arn" {
  description = "iam role for ec2 to access the s3 bucket"
}

variable "dr_ec2_role_arn" {
  description = "iam role for ec2 to access the s3 bucket"
}

