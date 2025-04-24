provider "aws" {
  region = "us-east-1"
  alias = "dr"
}

resource "aws_s3_bucket" "blog_bucket" {
  bucket = "blog-media-${var.environment}-${random_id.bucket_suffix.hex}"
  tags   = { Environment = var.environment }

}

resource "aws_s3_bucket_versioning" "blog_bucket_versioning" {
  bucket = aws_s3_bucket.blog_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# DR Bucket (us-east-1) - Separate provider
resource "aws_s3_bucket" "dr_bucket" {
  provider = aws.dr
  bucket   = "blog-media-dr-${random_id.bucket_suffix.hex}"
  tags     = { Environment = "dr" }

}

resource "aws_s3_bucket_versioning" "dr_bucket_versioning" {
  bucket = aws_s3_bucket.dr_bucket.id
  provider = aws.dr
  versioning_configuration {
    status = "Enabled"
  }

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

# public read access for images in dr bucket
resource "aws_s3_bucket_public_access_block" "dr_bucket" {
  provider = aws.dr
  bucket   = aws_s3_bucket.dr_bucket.id
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


# New: IAM Role for Replication (Add this)
resource "aws_iam_role" "replication" {
  name = "${var.environment}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "s3.amazonaws.com"
      }
    }]
  })
}

# New: Replication Policy
resource "aws_iam_policy" "replication" {
  name = "${var.environment}-s3-replication-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ],
        Effect   = "Allow",
        Resource = [aws_s3_bucket.blog_bucket.arn]
      },
      {
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl"
        ],
        Effect   = "Allow",
        Resource = ["${aws_s3_bucket.blog_bucket.arn}/*"]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ],
        Effect   = "Allow",
        Resource = ["${aws_s3_bucket.dr_bucket.arn}/*"]
      }
    ]
  })
}

# ttach Policy to Role
resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

# Replication Configuration
resource "aws_s3_bucket_replication_configuration" "replication" {
  depends_on = [
    aws_s3_bucket_policy.blog_bucket_policy,  # Ensure policy exists first
    aws_s3_bucket_versioning.blog_bucket_versioning,
    aws_s3_bucket_versioning.dr_bucket_versioning
  ]

  bucket = aws_s3_bucket.blog_bucket.id
  role   = aws_iam_role.replication.arn

  rule {
    id     = "blog-media-replication"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.dr_bucket.arn
      storage_class = "STANDARD"
    }
  }
}

resource "aws_s3_bucket_policy" "dr_bucket_policy" {
  provider = aws.dr
  bucket   = aws_s3_bucket.dr_bucket.id
  policy   = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowDRInstanceAccess",
        Effect    = "Allow",
        Principal = {
          AWS = var.dr_ec2_role_arn  # DR EC2 instance role ARN
        },
        Action    = ["s3:GetObject", "s3:PutObject"],
        Resource  = ["${aws_s3_bucket.dr_bucket.arn}/*"]
      }
    ]
  })
}

resource "aws_ssm_parameter" "primary_s3_name" {
  name = "/primary/s3-bucket-name"
  type = "String"
  value = aws_s3_bucket.blog_bucket.bucket
}


resource "aws_ssm_parameter" "dr_s3_name" {
  provider = aws.dr
  name = "/dr/s3-bucket-name"
  type = "String"
  value = aws_s3_bucket.dr_bucket.bucket
}