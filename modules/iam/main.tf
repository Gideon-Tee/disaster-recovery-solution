provider "aws" {
  region = "us-east-1"
  alias = "dr"
}

provider "aws" {
  region = "eu-west-1"
  alias = "primary"
}


resource "aws_iam_role" "ec2_s3_access" {
  name = "${var.environment}-ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role" "dr_ec2_s3_access" {
  name = "dr-ec2-s3-role"
  provider = aws.dr
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name = "${var.environment}-s3-access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
      Effect   = "Allow",
      Resource = ["arn:aws:s3:::${var.s3_bucket_name}/*"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.ec2_s3_access.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_s3_access.name
}

output "ec2_instance_profile_arn" {
  value = aws_iam_instance_profile.ec2_profile.arn
}

output "ec2_role_arn" {
  value = aws_iam_role.ec2_s3_access.arn
}

output "dr_ec2_role_arn" {
  value = aws_iam_role.dr_ec2_s3_access.arn
}