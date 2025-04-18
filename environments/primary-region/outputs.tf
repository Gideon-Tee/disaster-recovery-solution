output "Load_balancer_dns" {
  value = module.primary_load_balancer.alb_dns_name
}

output "RDS_endpoint" {
  value = module.primary_db.primary_db_endpoint
}