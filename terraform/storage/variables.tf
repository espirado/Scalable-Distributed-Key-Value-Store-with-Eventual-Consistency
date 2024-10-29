variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "kms_key_deletion_window" {
  description = "Waiting period for KMS key deletion"
  type        = number
  default     = 7
}

variable "bucket_force_destroy" {
  description = "Force destroy for S3 buckets"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 90
}
