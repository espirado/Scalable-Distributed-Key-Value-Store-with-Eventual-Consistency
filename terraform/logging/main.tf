locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Create Namespace first
resource "kubernetes_namespace" "logging" {
  metadata {
    name = "${var.project_name}-${var.environment}-logging"
  }
}

# Create Service Account without annotations first
resource "kubernetes_service_account" "fluentbit" {
  metadata {
    name      = "fluentbit"
    namespace = kubernetes_namespace.logging.metadata[0].name
  }
}

# Get EKS and OIDC provider information
data "aws_eks_cluster" "this" {
  name = var.eks_cluster_name
}

data "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# Create IAM policy first
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

# Create IRSA role
module "irsa_fluentbit" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${local.name_prefix}-fluentbit"

  role_policy_arns = {
    fluentbit = aws_iam_policy.fluentbit.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.eks.arn
      namespace_service_accounts = ["${kubernetes_namespace.logging.metadata[0].name}:fluentbit"]
    }
  }
}

# Update Service Account with annotation
resource "kubernetes_annotations" "fluentbit_sa" {
  api_version = "v1"
  kind        = "ServiceAccount"
  metadata {
    name      = kubernetes_service_account.fluentbit.metadata[0].name
    namespace = kubernetes_namespace.logging.metadata[0].name
  }
  annotations = {
    "eks.amazonaws.com/role-arn" = module.irsa_fluentbit.iam_role_arn
  }

  depends_on = [
    kubernetes_service_account.fluentbit,
    module.irsa_fluentbit
  ]
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

# Security Groups
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

# Fluent Bit ConfigMap
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
resource "kubernetes_daemonset" "fluentbit" {
  depends_on = [kubernetes_annotations.fluentbit_sa]

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

          resources {
            limits = {
              memory = "512Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
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

        toleration {
          key      = "node-role.kubernetes.io/master"
          operator = "Exists"
          effect   = "NoSchedule"
        }
      }
    }
  }
}

data "aws_region" "current" {}