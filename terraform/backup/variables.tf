variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = map(number)
  default = {
    daily   = 30
    weekly  = 90
    monthly = 365
  }
}

variable "backup_schedule" {
  description = "Backup schedule in cron format"
  type        = map(string)
  default = {
    daily   = "cron(0 0 * * ? *)"    # Every day at midnight UTC
    weekly  = "cron(0 0 ? * SUN *)"  # Every Sunday at midnight UTC
    monthly = "cron(0 0 1 * ? *)"    # First day of every month at midnight UTC
  }
}

variable "kms_key_arn" {
  description = "ARN of KMS key for backup encryption"
  type        = string
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}