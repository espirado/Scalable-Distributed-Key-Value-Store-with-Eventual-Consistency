output "jaeger_query_endpoint" {
  description = "Jaeger query service endpoint"
  value       = "http://jaeger-query.${kubernetes_namespace.tracing.metadata[0].name}:16686"
}

output "otel_collector_endpoint" {
  description = "OpenTelemetry Collector endpoint"
  value       = "${local.name_prefix}-collector.${kubernetes_namespace.tracing.metadata[0].name}:4317"
}

output "tracing_namespace" {
  description = "Kubernetes namespace for tracing"
  value       = kubernetes_namespace.tracing.metadata[0].name
}