output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "nat_gateway_public_ips" {
  description = "List of public IPs of the NAT Gateways"
  value       = module.nat.nat_gateway_public_ips
}


output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "vpc_flow_logs_group" {
  description = "VPC Flow Logs CloudWatch Log Group name"
  value       = module.vpc_flow_logs.log_group_name
}
output "alb_dns_name" {
  description = "DNS name of the application load balancer"
  value       = module.alb.alb_dns_name
}
output "vpc_endpoints" {
  description = "VPC Endpoint IDs"
  value = {
    interface = module.vpc_endpoints.interface_endpoints
    gateway   = module.vpc_endpoints.gateway_endpoints
  }
}

output "api_endpoint" {
  description = "Public API endpoint"
  value       = module.route53.api_endpoint
}

output "internal_api_endpoint" {
  description = "Internal API endpoint"
  value       = module.route53.internal_api_endpoint
}

output "cloudwatch_dashboard" {
  description = "CloudWatch dashboard name"
  value       = module.cloudwatch.dashboard_name
}

output "storage_config" {
  description = "Storage configuration details"
  value = {
    backup_bucket = module.storage.backup_bucket_name
    logs_bucket   = module.storage.logs_bucket_name
    storage_class = module.storage.storage_class_name
  }
}

output "logging_endpoints" {
  description = "Logging infrastructure endpoints"
  value = {
    opensearch = module.logging.opensearch_endpoint
    kibana     = module.logging.opensearch_kibana_endpoint
  }
}

output "metrics_endpoints" {
  description = "Metrics infrastructure endpoints"
  value = {
    prometheus   = module.metrics.prometheus_endpoint
    grafana      = module.metrics.grafana_endpoint
    alertmanager = module.metrics.alertmanager_endpoint
  }
}