# RDS, read replicas, parameter store/secrets

# RDS Credentials managed by SSM Parameter Store
resource "random_password" "db_password" {
  length  = 16
  special = false
}

# Store DB username/password in SSM Parameter Store (SecureString)
resource "aws_ssm_parameter" "db_username" {
  name        = "/${var.environment}/db/username"
  description = "Database username"
  type        = "String"
  value       = "admin"
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.environment}/db/password"
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
  identifier              = "${var.environment}-primary-db"
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
  backup_retention_period = 7     # Daily backups for 7 days
}

