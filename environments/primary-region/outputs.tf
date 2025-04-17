output "Load_balancer_dns" {
  value = module.primary_load_balancer.alb_dns_name
}