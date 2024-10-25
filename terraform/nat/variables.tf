variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where NAT Gateways will be created"
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "List of private route table IDs"
  type        = list(string)
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "create_per_az_nat" {
  description = "Whether to create NAT Gateway per AZ for high availability"
  type        = bool
  default     = true
}