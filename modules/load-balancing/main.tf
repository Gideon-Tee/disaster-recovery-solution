# ALBs,

# Application Load Balancer
resource "aws_lb" "app_alb" {
  name               = "${var.environment}-app-alb"
  internal           = false  # Public-facing ALB
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids  # Public subnets

  tags = {
    Environment = var.environment
  }
}

# Target group for ASG instances
resource "aws_lb_target_group" "app_tg" {
  name     = "${var.environment}-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# ALB listener (HTTP)
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}