locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Define subdomain based on environment
  subdomain = var.environment == "prod" ? var.domain_name : "${var.environment}.${var.domain_name}"
}

# Public Hosted Zone
resource "aws_route53_zone" "public" {
  name = local.subdomain

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-public-zone"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

# Private Hosted Zone (optional)
resource "aws_route53_zone" "private" {
  count = var.create_private_zone ? 1 : 0

  name = "${local.subdomain}.internal"

  vpc {
    vpc_id = var.vpc_id
  }

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-private-zone"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

# ALB Record in Public Zone
resource "aws_route53_record" "alb_public" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "api.${local.subdomain}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id               = var.alb_zone_id
    evaluate_target_health = true
  }
}

# ALB Record in Private Zone
resource "aws_route53_record" "alb_private" {
  count = var.create_private_zone ? 1 : 0

  zone_id = aws_route53_zone.private[0].zone_id
  name    = "api.${local.subdomain}.internal"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id               = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Health Check for API endpoint
resource "aws_route53_health_check" "api" {
  fqdn              = "api.${local.subdomain}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = "3"
  request_interval  = "30"

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-api-health-check"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

# CloudWatch Alarms for DNS
resource "aws_cloudwatch_metric_alarm" "dns_health_check" {
  alarm_name          = "${local.name_prefix}-dns-health-check"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "This metric monitors DNS health check status"

  dimensions = {
    HealthCheckId = aws_route53_health_check.api.id
  }

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-dns-alarm"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}