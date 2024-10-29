locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# OpenSearch Domain
resource "aws_opensearch_domain" "logging" {
  domain_name    = "${local.name_prefix}-logs"
  engine_version = "OpenSearch_2.5"

  cluster_config {
    instance_type            = var.opensearch_instance_type
    instance_count          = var.opensearch_instance_count
    zone_awareness_enabled  = true
    
    zone_awareness_config {
      availability_zone_count = 2
    }
  }

  vpc_options {
    subnet_ids         = [var.private_subnet_ids[0], var.private_subnet_ids[1]]
    security_group_ids = [aws_security_group.opensearch.id]
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 100
    volume_type = "gp3"
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  tags = {
    Name        = "${local.name_prefix}-opensearch"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Security Group for OpenSearch
resource "aws_security_group" "opensearch" {
  name        = "${local.name_prefix}-opensearch-sg"
  description = "Security group for OpenSearch domain"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.fluentbit.id]
  }

  tags = {
    Name        = "${local.name_prefix}-opensearch-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Security Group for Fluent Bit
resource "aws_security_group" "fluentbit" {
  name        = "${local.name_prefix}-fluentbit-sg"
  description = "Security group for Fluent Bit"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-fluentbit-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Fluent Bit Configuration
resource "kubernetes_config_map" "fluentbit_config" {
  metadata {
    name      = "fluentbit-config"
    namespace = kubernetes_namespace.logging.metadata[0].name
  }

  data = {
    "fluent-bit.conf" = <<EOF
[SERVICE]
    Flush         5
    Log_Level     info
    Daemon        off
    Parsers_File  parsers.conf

[INPUT]
    Name             tail
    Path             /var/log/containers/*.log
    Parser           docker
    Tag              kube.*
    Refresh_Interval 5
    Mem_Buf_Limit    5MB
    Skip_Long_Lines  On

[FILTER]
    Name                kubernetes
    Match               kube.*
    Kube_URL            https://kubernetes.default.svc:443
    Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
    Merge_Log           On
    K8S-Logging.Parser  On
    K8S-Logging.Exclude On

[OUTPUT]
    Name            es
    Match           *
    Host            ${aws_opensearch_domain.logging.endpoint}
    Port            443
    TLS             On
    AWS_Auth        On
    AWS_Region      ${data.aws_region.current.name}
    Index           kvstore-logs
    Type            _doc
EOF
  }
}

# Fluent Bit DaemonSet
resource "kubernetes_daemon_set" "fluentbit" {
  metadata {
    name      = "fluentbit"
    namespace = kubernetes_namespace.logging.metadata[0].name
  }

  spec {
    selector {
      match_labels = {
        app = "fluentbit"
      }
    }

    template {
      metadata {
        labels = {
          app = "fluentbit"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.fluentbit.metadata[0].name

        container {
          name  = "fluentbit"
          image = "fluent/fluent-bit:1.9"

          volume_mount {
            name       = "config"
            mount_path = "/fluent-bit/etc/"
          }

          volume_mount {
            name       = "varlog"
            mount_path = "/var/log"
          }

          volume_mount {
            name       = "varlibdockercontainers"
            mount_path = "/var/lib/docker/containers"
            read_only  = true
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.fluentbit_config.metadata[0].name
          }
        }

        volume {
          name = "varlog"
          host_path {
            path = "/var/log"
          }
        }

        volume {
          name = "varlibdockercontainers"
          host_path {
            path = "/var/lib/docker/containers"
          }
        }
      }
    }
  }
}

# Create Namespace
resource "kubernetes_namespace" "logging" {
  metadata {
    name = "${var.project_name}-${var.environment}-logging"
  }
}

# Service Account for Fluent Bit
resource "kubernetes_service_account" "fluentbit" {
  metadata {
    name      = "fluentbit"
    namespace = kubernetes_namespace.logging.metadata[0].name
  }
}

# IRSA for Fluent Bit
module "irsa_fluentbit" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${local.name_prefix}-fluentbit"

  oidc_providers = {
    main = {
      provider_arn = var.eks_cluster_endpoint
      namespace_service_accounts = ["${kubernetes_namespace.logging.metadata[0].name}:${kubernetes_service_account.fluentbit.metadata[0].name}"]
    }
  }

  role_policy_arns = [
    aws_iam_policy.fluentbit.arn
  ]
}

# IAM Policy for Fluent Bit
resource "aws_iam_policy" "fluentbit" {
  name        = "${local.name_prefix}-fluentbit"
  description = "IAM policy for Fluent Bit to access OpenSearch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "es:ESHttp*"
        ]
        Resource = "${aws_opensearch_domain.logging.arn}/*"
      }
    ]
  })
}

data "aws_region" "current" {}
