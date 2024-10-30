locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Define common interface endpoints needed
  interface_endpoints = {
    ecr_api = {
      service_name = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
      private_dns  = true
    }
    ecr_dkr = {
      service_name = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
      private_dns  = true
    }
    logs = {
      service_name = "com.amazonaws.${data.aws_region.current.name}.logs"
      private_dns  = true
    }
    cloudwatch = {
      service_name = "com.amazonaws.${data.aws_region.current.name}.monitoring"
      private_dns  = true
    }
    sts = {
      service_name = "com.amazonaws.${data.aws_region.current.name}.sts"
      private_dns  = true
    }
    eks = {
      service_name = "com.amazonaws.${data.aws_region.current.name}.eks"
      private_dns  = true
    }
  }

  # Define gateway endpoints needed
  gateway_endpoints = {
    s3 = {
      service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
    }
    dynamodb = {
      service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
    }
  }
}

data "aws_region" "current" {}

# Interface Endpoints
resource "aws_vpc_endpoint" "interface_endpoints" {
  for_each = local.interface_endpoints

  vpc_id              = var.vpc_id
  service_name        = each.value.service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = each.value.private_dns

  tags = {
    Name        = "${local.name_prefix}-${each.key}-endpoint"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Gateway Endpoints
resource "aws_vpc_endpoint" "gateway_endpoints" {
  for_each = local.gateway_endpoints

  vpc_id            = var.vpc_id
  service_name      = each.value.service_name
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids

  tags = {
    Name        = "${local.name_prefix}-${each.key}-endpoint"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.name_prefix}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  tags = {
    Name        = "${local.name_prefix}-vpc-endpoints-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}
