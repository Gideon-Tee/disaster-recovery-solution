variable "environment" {
  description = "Environment (primary/dr)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for security groups and subnets"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for RDS subnet group"
  type        = list(string)
}

variable "database_engine" {
  description = "Database engine (mysql/postgres etc)"
  type        = string
  default     = "mysql"
}

variable "database_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0"  # For MySQL
}

variable "instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appDB"
}

variable "allocated_storage" {
  description = "Storage size in GB"
  type        = number
  default     = 20
}

variable "dr_vpc_id" {
  description = "VPC ID in DR region"
  type        = string
}

variable "dr_private_subnet_ids" {
  description = "List of private subnet IDs in DR region"
  type        = list(string)
}