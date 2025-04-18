resource "aws_s3_bucket" "blog_bucket" {
  bucket = "blog-media-${var.environment}-${random_id.bucket_suffix.hex}"
  tags   = { Environment = var.environment }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Allow public read access for images
resource "aws_s3_bucket_public_access_block" "blog_bucket" {
  bucket = aws_s3_bucket.blog_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "blog_bucket_policy" {
  bucket = aws_s3_bucket.blog_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowPublicRead",
        Effect    = "Allow",
        Principal = "*",
        Action    = ["s3:GetObject"],
        Resource  = ["${aws_s3_bucket.blog_bucket.arn}/*"]
      },
      {
        Sid       = "AllowAppUpload",
        Effect    = "Allow",
        Principal = {
          AWS = var.ec2_role_arn  # EC2 instance role ARN
        },
        Action    = ["s3:PutObject", "s3:PutObjectAcl"],
        Resource  = ["${aws_s3_bucket.blog_bucket.arn}/*"]
      }
    ]
  })
}

output "blog_bucket_arn" {
  value = aws_s3_bucket.blog_bucket.arn
}

output "blog_bucket_id" {
  value = aws_s3_bucket.blog_bucket.id
}

