output "opensearch_endpoint" {
  description = "OpenSearch domain endpoint"
  value       = aws_opensearch_domain.logging.endpoint
}


output "opensearch_dashboard_endpoint" {
  description = "OpenSearch dashboard endpoint"
  value       = aws_opensearch_domain.logging.dashboard_endpoint
}

output "fluentbit_namespace" {
  description = "Kubernetes namespace for logging"
  value       = kubernetes_namespace.logging.metadata[0].name
}