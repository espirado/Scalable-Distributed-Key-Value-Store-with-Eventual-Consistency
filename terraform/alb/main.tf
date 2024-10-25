locals {
  name_prefix = "${var.project}-${var.environment}"
}

# Create ALB
resource "aws_lb" "kvstore" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.environment == "prod" ? true : false

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-alb"
      Environment = var.environment
      Project     = var.project
    }
  )
}

# Create target group
resource "aws_lb_target_group" "kvstore" {
  name     = "${local.name_prefix}-tg"
  port     = var.kvstore_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = var.health_check_path
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-299"
  }

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-tg"
      Environment = var.environment
      Project     = var.project
    }
  )
}

# Create listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.kvstore.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kvstore.arn
  }

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-http-listener"
      Environment = var.environment
      Project     = var.project
    }
  )
}

# Optional HTTPS listener
resource "aws_lb_listener" "https" {
  count = var.create_https_listener ? 1 : 0

  load_balancer_arn = aws_lb.kvstore.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kvstore.arn
  }

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-https-listener"
      Environment = var.environment
      Project     = var.project
    }
  )
}
