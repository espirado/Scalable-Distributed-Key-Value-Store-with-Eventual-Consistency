variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "retention_days" {
  description = "Number of days to retain metrics"
  type        = number
  default     = 15
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  sensitive   = true
}

# Network configuration
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

# Cluster configuration
variable "cluster_endpoint" {
  description = "Endpoint for your EKS cluster"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Cluster CA certificate"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}