
output "blog_bucket_arn" {
  value = aws_s3_bucket.blog_bucket.arn
}

output "blog_bucket_id" {
  value = aws_s3_bucket.blog_bucket.id
}

output "dr_bucket_arn" {
  value = aws_s3_bucket.dr_bucket.arn
}

output "dr_s3_bucket_name" {
  value = aws_s3_bucket.dr_bucket.bucket
}