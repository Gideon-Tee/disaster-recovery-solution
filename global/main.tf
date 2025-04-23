provider "aws" {
  region = "us-east-1"
  alias = "dr"
}

resource "aws_globalaccelerator_accelerator" "app_accelerator" {
  name            = "app-global-accelerator"
  ip_address_type = "IPV4"
  enabled         = true

  attributes {
    flow_logs_enabled   = false # Optional: Enable if you need flow logs
    flow_logs_s3_bucket = null
    flow_logs_s3_prefix = null
  }
}

resource "aws_globalaccelerator_listener" "app_listener" {
  accelerator_arn = aws_globalaccelerator_accelerator.app_accelerator.arn
  protocol        = "TCP"
  port_range {
    from_port = 80
    to_port   = 80
  }
}

# Primary region endpoint group (eu-west-1)
resource "aws_globalaccelerator_endpoint_group" "primary" {
  listener_arn          = aws_globalaccelerator_listener.app_listener.arn
  endpoint_group_region = var.primary_region
  health_check_path     = "/" # Health check endpoint
  health_check_port     = 80
  health_check_protocol = "HTTP"
  health_check_interval_seconds = 10
  threshold_count               = 3

  endpoint_configuration {
    endpoint_id             = var.primary_alb_arn
    weight                  = 100 # Higher weight for primary
    client_ip_preservation_enabled = true
  }

  traffic_dial_percentage = 100 # Send all traffic to primary under normal conditions
}

# DR region endpoint group (us-east-1)
resource "aws_globalaccelerator_endpoint_group" "dr" {
  listener_arn          = aws_globalaccelerator_listener.app_listener.arn
  endpoint_group_region = var.dr_region
  health_check_path     = "/" # Health check endpoint
  health_check_port     = 80
  health_check_protocol = "HTTP"
  health_check_interval_seconds = 10
  threshold_count               = 3

  endpoint_configuration {
    endpoint_id             = var.dr_alb_arn
    weight                  = 10 # Lower weight for DR
    client_ip_preservation_enabled = true
  }

  traffic_dial_percentage = 0 # No traffic to DR under normal conditions
}