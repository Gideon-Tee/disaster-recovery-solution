variable "environment" {
  description = "Environment for deployment"
  type = string
}

variable "s3_bucket_name" {
  description = "s3 bucket for app static files"
  type = string
}