variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "kvstore"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones in us-east-1"
  type        = list(string)
  default     = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c"
  ]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = [
    "10.0.0.0/19",
    "10.0.32.0/19",
    "10.0.64.0/19"
  ]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = [
    "10.0.96.0/19",
    "10.0.128.0/19",
    "10.0.160.0/19"
  ]
}

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default     = {
    Environment = "dev"
    Project     = "kvstore"
    ManagedBy   = "terraform"
    Owner       = "infrastructure-team"
  }
}
variable "kvstore_client_port" {
  description = "Port for KV store client connections"
  type        = number
  default     = 8080
}

variable "kvstore_peer_port" {
  description = "Port for KV store peer communication"
  type        = number
  default     = 7946
}

variable "kvstore_gossip_port" {
  description = "Port for gossip protocol"
  type        = number
  default     = 7947
}

variable "create_https_listener" {
  description = "Whether to create HTTPS listener"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN of ACM certificate for HTTPS"
  type        = string
  default     = null
}

variable "domain_name" {
  description = "Main domain name for the service"
  type        = string
}