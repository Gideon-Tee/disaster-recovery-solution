provider "aws" {
  region = "us-east-1"
  alias = "dr"
}
# VPC, subnets, route tables, etc.

# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

resource "aws_vpc" "dr_vpc" {
  cidr_block           = var.vpc_cidr
  provider = aws.dr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name        = "dr-vpc"
    Environment = var.environment
  }
}

# Public subnets for primary region
resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = "${var.region}${count.index % 2 == 0 ? "a" : "b"}"  # e.g., eu-west-1a, eu-west-1b
  tags = {
    Name = "${var.environment}-public-${count.index}"
  }
}

# Private subnets
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = "${var.region}${count.index % 2 == 0 ? "a" : "b"}"
  tags = {
    Name = "${var.environment}-private-${count.index}"
  }
}

# Public subnets for dr region
resource "aws_subnet" "dr-public_subnets" {
  count             = length(var.public_subnet_cidrs)
  provider = aws.dr
  vpc_id            = aws_vpc.dr_vpc.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = "${var.dr_region}${count.index % 2 == 0 ? "a" : "b"}"  # e.g., eu-west-1a, eu-west-1b
  tags = {
    Name = "dr-public-${count.index}"
  }
}

# Private subnets
resource "aws_subnet" "dr-private_subnets" {
  count             = length(var.private_subnet_cidrs)
  provider = aws.dr
  vpc_id            = aws_vpc.dr_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = "${var.dr_region}${count.index % 2 == 0 ? "a" : "b"}"
  tags = {
    Name = "dr-private-${count.index}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.environment}-igw"
  }
}

# Internet Gateway - DR region
resource "aws_internet_gateway" "dr-igw" {
  vpc_id = aws_vpc.dr_vpc.id
  provider = aws.dr
  tags = {
    Name = "dr-igw"
  }
}

# Route table for public subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.environment}-public-rt"
  }
}
# Route table for public subnets - DR region
resource "aws_route_table" "dr-public_rt" {
  vpc_id = aws_vpc.dr_vpc.id
  provider = aws.dr
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dr-igw.id
  }
  tags = {
    Name = "${var.environment}-public-rt"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public_rta" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Associate public subnets with public route table - dr
resource "aws_route_table_association" "dr-public_rta" {
  provider = aws.dr
  count          = length(aws_subnet.dr-public_subnets)
  subnet_id      = aws_subnet.dr-public_subnets[count.index].id
  route_table_id = aws_route_table.dr-public_rt.id
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}-alb-sg"
  description = "Allow HTTP/HTTPS to ALB"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for ALB in DR region
resource "aws_security_group" "dr-alb_sg" {
  name        = "${var.environment}-alb-sg"
  description = "Allow HTTP/HTTPS to ALB"
  provider = aws.dr
  vpc_id      = aws_vpc.dr_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
