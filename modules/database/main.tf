provider "aws" {
  region = "us-east-1"
  alias = "dr"
}

# KMS key in primary region
resource "aws_kms_key" "primary_db_key" {
  description             = "KMS key for primary RDS encryption"
  multi_region            = true
  enable_key_rotation     = true
}

# Replicate KMS key to DR region
resource "aws_kms_replica_key" "dr_db_key" {
  provider          = aws.dr
  description       = "Replica KMS key for DR RDS encryption"
  primary_key_arn   = aws_kms_key.primary_db_key.arn
}

# RDS Credentials managed by SSM Parameter Store
resource "random_password" "db_password" {
  length  = 16
  special = false
}

# Store DB username/password in SSM Parameter Store (SecureString)
resource "aws_ssm_parameter" "db_username" {
  name        = "/primary/db/username"
  description = "Database username"
  type        = "String"
  value       = "admin"
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/primary/db/password"
  description = "Database password"
  type        = "SecureString"
  value       = random_password.db_password.result
  # key_id      = aws_kms_key.dr_kms_key.arn  # Encrypt with KMS (from global resources)
}


# Security group for the rds instance
resource "aws_security_group" "db_sg" {
  name        = "${var.environment}-db-sg"
  description = "Allow traffic from app servers to RDS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306  # MySQL
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["12.0.0.0/16"]  # Restrict to VPC CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "primary-rds-SG"
  }
}

# Subnet group for RDS
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
}


# RDS instance
resource "aws_db_instance" "primary_db" {
  identifier              = "app-primary-db"
  engine                  = var.database_engine
  engine_version          = var.database_version
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  db_name                 = var.db_name
  username                = aws_ssm_parameter.db_username.value
  password                = aws_ssm_parameter.db_password.value
  multi_az                = false  # High availability within primary region ( enable in production )
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  skip_final_snapshot     = true  # Disable for production!
  storage_encrypted       = true  # Encrypt data at rest
  kms_key_id = aws_kms_key.primary_db_key.arn
  backup_retention_period = 7     # Daily backups for 7 days
}


# DR Region Security Group
resource "aws_security_group" "dr_db_sg" {
  provider    = aws.dr
  name        = "dr-app-db-sg"
  description = "Allow traffic from DR app servers to RDS"
  vpc_id      = var.dr_vpc_id  # Need to pass DR VPC ID from DR networking module

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["12.0.0.0/16"]  # DR VPC CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dr-rds-sg"
  }
}

# DR Subnet Group
resource "aws_db_subnet_group" "dr_db_subnet_group" {
  provider    = aws.dr
  name        = "${var.environment}-dr-db-subnet-group"
  subnet_ids  = var.dr_private_subnet_ids  # Need to pass DR subnet IDs
  description = "Subnet group for DR RDS instance"

  tags = {
    Name = "dr-db-subnet-group"
  }
}

# Cross-region read replica in DR region
resource "aws_db_instance" "dr_replica" {
  provider               = aws.dr
  identifier             = "app-db-replica"
  replicate_source_db    = aws_db_instance.primary_db.arn
  instance_class         = var.instance_class
  engine                 = var.database_engine
  engine_version         = var.database_version
  skip_final_snapshot    = true
  storage_encrypted      = true
  kms_key_id = aws_kms_replica_key.dr_db_key.arn
  backup_retention_period = 0  # Backups managed by primary

  # Important DR settings
  availability_zone      = "us-east-1a"
  multi_az               = false  # Can enable if needed for DR region HA

  # Copy tags from primary
  tags = {
    Name        = "${var.environment}-dr-replica"
    Environment = var.environment
    Role        = "dr-replica"
  }

  # Use DR region networking
  vpc_security_group_ids = [aws_security_group.dr_db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.dr_db_subnet_group.name

  lifecycle {
    ignore_changes = [
      # Ignore changes to these attributes as they're managed by the primary
      replicate_source_db,
      engine_version,
      storage_encrypted
    ]
  }
}

resource "aws_ssm_parameter" "rds_replica_endpoint" {
  provider = aws.dr
  name = "/dr/rds-endpoint"
  type = "String"
  value = aws_db_instance.dr_replica.endpoint
}