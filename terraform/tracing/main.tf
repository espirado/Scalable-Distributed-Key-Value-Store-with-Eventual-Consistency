locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Create Namespace
resource "kubernetes_namespace" "tracing" {
  metadata {
    name = "${local.name_prefix}-tracing"

    labels = {
      "app.kubernetes.io/name"      = "tracing"
      "app.kubernetes.io/component" = "monitoring"
      "app.kubernetes.io/part-of"   = var.project_name
    }
  }
}

# OpenTelemetry Operator
resource "helm_release" "opentelemetry_operator" {
  name       = "opentelemetry-operator"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-operator"
  namespace  = kubernetes_namespace.tracing.metadata[0].name
  version    = "0.24.0"  # Update to latest stable version

  set {
    name  = "admissionWebhooks.certManager.enabled"
    value = "true"
  }
}

# Jaeger Operator
resource "helm_release" "jaeger_operator" {
  name       = "jaeger-operator"
  repository = "https://jaegertracing.github.io/helm-charts"
  chart      = "jaeger-operator"
  namespace  = kubernetes_namespace.tracing.metadata[0].name
  version    = "2.37.0"  # Update to latest stable version

  values = [
    yamlencode({
      jaeger: {
        create: true
        spec: {
          strategy: "production"
          storage: {
            type: "elasticsearch"
            options: {
              es: {
                server-urls: module.elasticsearch.endpoint
                username: "elastic"
                password: random_password.elastic_password.result
              }
            }
          }
        }
      }
    })
  ]
}

# OpenTelemetry Collector
resource "kubernetes_manifest" "otel_collector" {
  manifest = {
    apiVersion = "opentelemetry.io/v1alpha1"
    kind       = "OpenTelemetryCollector"
    metadata = {
      name      = "${local.name_prefix}-collector"
      namespace = kubernetes_namespace.tracing.metadata[0].name
    }
    spec = {
      mode = "deployment"
      config = yamlencode({
        receivers: {
          otlp: {
            protocols: {
              grpc: {
                endpoint: "0.0.0.0:4317"
              }
              http: {
                endpoint: "0.0.0.0:4318"
              }
            }
          }
        }
        processors: {
          batch: {}
          memory_limiter: {
            check_interval: "1s"
            limit_mib: "1000"
          }
          resourcedetection: {
            detectors: ["env", "system", "kubernetes"]
          }
        }
        exporters: {
          jaeger: {
            endpoint: "jaeger-collector:14250"
            tls: {
              insecure: true
            }
          }
          logging: {
            loglevel: "debug"
          }
        }
        service: {
          pipelines: {
            traces: {
              receivers: ["otlp"]
              processors: ["memory_limiter", "batch", "resourcedetection"]
              exporters: ["jaeger", "logging"]
            }
          }
        }
      })
    }
  }

  depends_on = [
    helm_release.opentelemetry_operator,
    helm_release.jaeger_operator
  ]
}

# OpenTelemetry Instrumentation
resource "kubernetes_manifest" "otel_instrumentation" {
  manifest = {
    apiVersion = "opentelemetry.io/v1alpha1"
    kind       = "Instrumentation"
    metadata = {
      name      = "${local.name_prefix}-instrumentation"
      namespace = kubernetes_namespace.tracing.metadata[0].name
    }
    spec = {
      exporter = {
        endpoint = "http://${local.name_prefix}-collector:4318"
      }
      propagators = [
        "tracecontext",
        "baggage",
        "b3"
      ]
      sampler = {
        type = "parentbased_traceidratio"
        argument = "1.0"
      }
      env = [
        {
          name = "OTEL_SERVICE_NAME"
          valueFrom = {
            fieldRef = {
              fieldPath = "metadata.labels['app.kubernetes.io/name']"
            }
          }
        }
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.otel_collector
  ]
}

# Service Account for OTEL Collector
resource "kubernetes_service_account" "otel_collector" {
  metadata {
    name      = "otel-collector"
    namespace = kubernetes_namespace.tracing.metadata[0].name
  }
}

# Create ClusterRole for OTEL Collector
resource "kubernetes_cluster_role" "otel_collector" {
  metadata {
    name = "${local.name_prefix}-otel-collector"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "namespaces"]
    verbs      = ["get", "list", "watch"]
  }
}

# Create ClusterRoleBinding for OTEL Collector
resource "kubernetes_cluster_role_binding" "otel_collector" {
  metadata {
    name = "${local.name_prefix}-otel-collector"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.otel_collector.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.otel_collector.metadata[0].name
    namespace = kubernetes_namespace.tracing.metadata[0].name
  }
}
