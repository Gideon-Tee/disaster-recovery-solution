# # Remote state storage in S3 (primary region) with DynamoDB locking
# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"  # Replace with your bucket name
#     key            = "global/terraform.tfstate"    # State file path
#     region         = "eu-west-1"                   # Primary region for state
#     encrypt        = true                          # Encrypt state file
#     dynamodb_table = "terraform-lock"              # DynamoDB table for locks
#   }
# }