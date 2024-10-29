output "prometheus_endpoint" {
  description = "Prometheus server endpoint"
  value       = "http://prometheus-operated.${kubernetes_namespace.monitoring.metadata[0].name}:9090"
}

output "grafana_endpoint" {
  description = "Grafana server endpoint"
  value       = "http://prometheus-stack-grafana.${kubernetes_namespace.monitoring.metadata[0].name}"
}

output "alertmanager_endpoint" {
  description = "AlertManager endpoint"
  value       = "http://alertmanager-operated.${kubernetes_namespace.monitoring.metadata[0].name}:9093"
}