variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for flow logs"
  type        = string
}

variable "retention_days" {
  description = "Number of days to retain flow logs"
  type        = number
  default     = 30
}

variable "traffic_type" {
  description = "Type of traffic to log (ACCEPT, REJECT, ALL)"
  type        = string
  default     = "ALL"
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
