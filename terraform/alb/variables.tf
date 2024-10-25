variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for the ALB"
  type        = list(string)
}

variable "kvstore_port" {
  description = "Port for KV store service"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Health check path for targets"
  type        = string
  default     = "/health"
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
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