# Configure Terraform and AWS provider versions
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Default provider (primary region: eu-west-1)
provider "aws" {
  region = "eu-west-1"
  alias = "primary"
  default_tags {
    tags = {
      Environment = "primary"
      Project     = "disaster-recovery"
    }
  }
}

# DR region provider alias (us-east-1)
provider "aws" {
  alias  = "dr"
  region = "us-east-1"
  default_tags {
    tags = {
      Environment = "dr"
      Project     = "disaster-recovery"
    }
  }
}