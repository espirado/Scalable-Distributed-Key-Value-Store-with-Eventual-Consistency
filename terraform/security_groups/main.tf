locals {
  name_prefix = "${var.project}-${var.environment}"
}

# Security Group for KV Store Nodes
resource "aws_security_group" "kvstore_nodes" {
  name        = "${local.name_prefix}-kvstore-nodes-sg"
  description = "Security group for KV store nodes"
  vpc_id      = var.vpc_id

  # Allow incoming client requests
  ingress {
    description = "Client connections"
    from_port   = var.kvstore_client_port
    to_port     = var.kvstore_client_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow peer-to-peer communication
  ingress {
    description = "Peer communication"
    from_port   = var.kvstore_peer_port
    to_port     = var.kvstore_peer_port
    protocol    = "tcp"
    self        = true
  }

  # Allow gossip protocol communication
  ingress {
    description = "Gossip protocol"
    from_port   = var.kvstore_gossip_port
    to_port     = var.kvstore_gossip_port
    protocol    = "udp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-kvstore-nodes-sg"
    Environment = var.environment
    Project     = var.project
  }
}

# Security Group for Load Balancer
resource "aws_security_group" "kvstore_lb" {
  name        = "${local.name_prefix}-kvstore-lb-sg"
  description = "Security group for KV store load balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "Client API Access"
    from_port   = var.kvstore_client_port
    to_port     = var.kvstore_client_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-kvstore-lb-sg"
    Environment = var.environment
    Project     = var.project
  }
}

# Security Group for Management/Monitoring
resource "aws_security_group" "kvstore_monitoring" {
  name        = "${local.name_prefix}-kvstore-monitoring-sg"
  description = "Security group for KV store monitoring"
  vpc_id      = var.vpc_id

  ingress {
    description = "Prometheus metrics"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Node exporter metrics"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-kvstore-monitoring-sg"
    Environment = var.environment
    Project     = var.project
  }
}