locals {
  name_prefix = "${var.project}-${var.environment}"
}

# Application Load Balancer
resource "aws_lb" "kvstore" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.public_subnet_ids

  # Enable deletion protection in production
  enable_deletion_protection = var.environment == "prod" ? true : false

  # Enable access logs if needed
  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.id
  #   prefix  = "alb-logs"
  #   enabled = true
  # }

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-alb"
      Environment = var.environment
      Project     = var.project
    }
  )
}

# Target Group
resource "aws_lb_target_group" "kvstore" {
  name     = "${local.name_prefix}-tg"
  port     = var.kvstore_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # Configure health checks
  health_check {
    enabled             = true
    path                = var.health_check_path
    port                = "traffic-port"
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    matcher             = "200-299"  # Success codes
  }

  # Target group attributes
  stickiness {
    type = "lb_cookie"  # ALB-generated cookie for session stickiness
    enabled = true
    cookie_duration = 86400  # 24 hours
  }

  deregistration_delay = var.deregistration_delay

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-tg"
      Environment = var.environment
      Project     = var.project
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# HTTP Listener
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

# CloudWatch Alarms for ALB
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${local.name_prefix}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "ALB 5XX errors exceeded threshold"

  dimensions = {
    LoadBalancer = aws_lb.kvstore.arn_suffix
  }

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-alb-5xx-alarm"
      Environment = var.environment
      Project     = var.project
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "target_response_time" {
  alarm_name          = "${local.name_prefix}-target-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "2"  # 2 seconds
  alarm_description   = "Target response time exceeded threshold"

  dimensions = {
    LoadBalancer = aws_lb.kvstore.arn_suffix
    TargetGroup  = aws_lb_target_group.kvstore.arn_suffix
  }

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-response-time-alarm"
      Environment = var.environment
      Project     = var.project
    }
  )
}