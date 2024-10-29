output "opensearch_endpoint" {
  description = "OpenSearch domain endpoint"
  value       = aws_opensearch_domain.logging.endpoint
}

output "opensearch_kibana_endpoint" {
  description = "OpenSearch Kibana endpoint"
  value       = aws_opensearch_domain.logging.kibana_endpoint
}

output "fluentbit_namespace" {
  description = "Kubernetes namespace for logging"
  value       = kubernetes_namespace.logging.metadata[0].name
}