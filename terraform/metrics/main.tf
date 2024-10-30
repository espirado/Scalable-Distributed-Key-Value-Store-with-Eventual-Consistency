locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Create Monitoring Namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "${local.name_prefix}-monitoring"
    
    labels = {
      "app.kubernetes.io/name"      = "monitoring"
      "app.kubernetes.io/part-of"   = var.project_name
      "kubernetes.io/metadata.name" = "monitoring"
    }
  }
}

# Install Prometheus Stack using Helm
resource "helm_release" "prometheus_stack" {
  name       = "prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "45.7.1"  # Update to latest stable version

  values = [
    yamlencode({
      prometheus: {
        prometheusSpec: {
          retention: "${var.retention_days}d"
          storageSpec: {
            volumeClaimTemplate: {
              spec: {
                storageClassName: "gp3"
                accessModes: ["ReadWriteOnce"]
                resources: {
                  requests: {
                    storage: "50Gi"
                  }
                }
              }
            }
          }
          additionalScrapeConfigs: [
            {
              job_name: "kvstore-metrics"
              kubernetes_sd_configs: [{
                role: "pod"
                namespaces: {
                  names: ["${var.project_name}-${var.environment}"]
                }
              }]
              relabel_configs: [
                {
                  source_labels: ["__meta_kubernetes_pod_annotation_prometheus_io_scrape"]
                  action: "keep"
                  regex: true
                },
                {
                  source_labels: ["__meta_kubernetes_pod_annotation_prometheus_io_path"]
                  action: "replace"
                  target_label: "__metrics_path__"
                  regex: "(.+)"
                }
              ]
            }
          ]
        }
      }
      grafana: {
        adminPassword: var.grafana_admin_password
        persistence: {
          enabled: true
          size: "10Gi"
          storageClassName: "gp3"
        }
        dashboardProviders: {
          "dashboardproviders.yaml": {
            apiVersion: 1
            providers: [
              {
                name: "default"
                orgId: 1
                folder: ""
                type: "file"
                disableDeletion: false
                editable: true
                options: {
                  path: "/var/lib/grafana/dashboards"
                }
              }
            ]
          }
        }
        dashboards: {
          default: {
            kvstore-dashboard: {
              json: file("${path.module}/dashboards/kvstore-dashboard.json")
            }
          }
        }
        sidecar: {
          datasources: {
            enabled: true
          }
          dashboards: {
            enabled: true
          }
        }
      }
    })
  ]
}

# Create ServiceMonitor for KVStore
resource "kubernetes_manifest" "kvstore_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "${local.name_prefix}-servicemonitor"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        "app.kubernetes.io/name" = "kvstore"
        "app.kubernetes.io/part-of" = var.project_name
      }
    }
    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "kvstore"
        }
      }
      endpoints = [
        {
          port = "metrics"
          path = "/metrics"
          interval = "15s"
          scrapeTimeout = "10s"
        }
      ]
      namespaceSelector = {
        matchNames = ["${var.project_name}-${var.environment}"]
      }
    }
  }

  depends_on = [
    helm_release.prometheus_stack
  ]
}

# Create Prometheus Rules
resource "kubernetes_manifest" "kvstore_prometheusrule" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "${local.name_prefix}-rules"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        "app.kubernetes.io/name" = "kvstore"
        "app.kubernetes.io/part-of" = var.project_name
      }
    }
    spec = {
      groups = [
        {
          name = "kvstore.rules"
          rules = [
            {
              alert = "HighLatency"
              expr  = "rate(kvstore_operation_duration_seconds_sum[5m]) / rate(kvstore_operation_duration_seconds_count[5m]) > 0.1"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary = "High operation latency detected"
                description = "KVStore operations are taking longer than expected"
              }
            },
            {
              alert = "HighErrorRate"
              expr  = "rate(kvstore_operation_errors_total[5m]) / rate(kvstore_operation_total[5m]) > 0.05"
              for   = "5m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary = "High error rate detected"
                description = "KVStore error rate is above 5%"
              }
            }
          ]
        }
      ]
    }
  }

  depends_on = [
    helm_release.prometheus_stack
  ]
}

# Alert Configuration for Slack
resource "kubernetes_secret" "alertmanager_config" {
  metadata {
    name      = "alertmanager-config"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "alertmanager.yaml" = yamlencode({
      global: {
        resolve_timeout: "5m"
      }
      route: {
        group_by: ["alertname", "job"]
        group_wait: "30s"
        group_interval: "5m"
        repeat_interval: "12h"
        receiver: "slack"
        routes: [
          {
            match: {
              severity: "critical"
            }
            receiver: "slack"
          }
        ]
      }
      receivers: [
        {
          name: "slack"
          slack_configs: [
            {
              channel: "#alerts"
              api_url: "https://hooks.slack.com/services/YOUR-WEBHOOK-URL"
              send_resolved: true
              title: "{{ .GroupLabels.alertname }}"
              text: "{{ .CommonAnnotations.description }}"
            }
          ]
        }
      ]
    })
  }

  depends_on = [
    helm_release.prometheus_stack
  ]
}
