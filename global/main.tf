

# Define KMS key policy to allow cross-region access and encryption/decryption
data "aws_iam_policy_document" "kms_policy" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "Allow DR Lambda to use the key"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.dr_lambda_role.arn]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Allow SSM to use the key (for Parameter Store)"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}


# Create KMS key for encrypting secrets (AMI, RDS, etc.)
resource "aws_kms_key" "dr_kms_key" {
  description             = "KMS key for DR resources encryption"
  enable_key_rotation    = true
  deletion_window_in_days = 30
  policy = data.aws_iam_policy_document.kms_policy.json
}

# KMS alias for easy reference
resource "aws_kms_alias" "dr_kms_alias" {
  name          = "alias/dr-kms-key"
  target_key_id = aws_kms_key.dr_kms_key.key_id
}

# IAM role for Lambda (DR automation)
resource "aws_iam_role" "dr_lambda_role" {
  name = "dr-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM policy for Lambda to manage ASG, RDS, and SSM
resource "aws_iam_policy" "dr_lambda_policy" {
  name = "dr-lambda-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "autoscaling:SetDesiredCapacity",
          "rds:PromoteReadReplica",
          "ssm:GetParameter",
          "kms:Decrypt"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.dr_lambda_role.name
  policy_arn = aws_iam_policy.dr_lambda_policy.arn
}

# S3 bucket for cross-region replication (if needed)
resource "aws_s3_bucket" "dr_artifacts" {
  bucket = "dr-artifacts-${data.aws_caller_identity.current.account_id}"
  force_destroy = true  # Caution: Enable only for demo purposes
}

# Enable S3 bucket versioning
resource "aws_s3_bucket_versioning" "dr_artifacts" {
  bucket = aws_s3_bucket.dr_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}
