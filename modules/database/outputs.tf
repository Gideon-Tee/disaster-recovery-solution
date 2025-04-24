output "primary_db_endpoint" {
  description = "Primary RDS endpoint"
  value       = aws_db_instance.primary_db.endpoint
}

output "db_username" {
  value = aws_db_instance.primary_db.username
}

output "db_password" {
  value = aws_db_instance.primary_db.password
}

output "primary_rds_identifier" {
  value = aws_db_instance.primary_db.identifier
}

output "dr_rds_identifier" {
  value = aws_db_instance.dr_replica.identifier
}

output "dr_replica_db_endpoint" {
  value = aws_db_instance.dr_replica.endpoint
}