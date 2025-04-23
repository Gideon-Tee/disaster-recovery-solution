output "Load_balancer_dns" {
  value = module.primary_load_balancer.alb_dns_name
}

output "RDS_endpoint" {
  value = module.primary_db.primary_db_endpoint
}

output "DR_bucket_arn" {
  value = module.storage.dr_bucket_arn
}

output "Global_Accelerator_dns_name" {
  value = module.global.global_accelerator_dns_name
}