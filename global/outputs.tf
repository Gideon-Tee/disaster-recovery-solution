output "kms_key_arn" {
  description = "ARN of the KMS key for encryption"
  value       = aws_kms_key.dr_kms_key.arn
}

output "lambda_role_arn" {
  description = "ARN of the IAM role for Lambda functions"
  value       = aws_iam_role.dr_lambda_role.arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for DR artifacts"
  value       = aws_s3_bucket.dr_artifacts.bucket
}