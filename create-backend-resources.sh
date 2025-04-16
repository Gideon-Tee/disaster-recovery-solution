#!/bin/bash

echo "Creating s3 bucket for terraform state"
# Create S3 bucket (enable versioning!)
aws s3api create-bucket --bucket dr-project-state-gmt --region eu-west-1 --create-bucket-configuration LocationConstraint=eu-west-1

echo "Enabling versioning"
# Enable encryption
aws s3api put-bucket-encryption --bucket dr-project-state-gmt --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
echo "Bucket created"

echo "Creating DynamoDB table"
# Create DynamoDB table
aws dynamodb create-table --table-name dr-project-terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-west-1

echo "DynamoDB table created"