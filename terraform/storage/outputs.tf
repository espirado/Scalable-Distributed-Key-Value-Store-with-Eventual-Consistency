output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.storage.arn
}

output "backup_bucket_name" {
  description = "Name of the backup S3 bucket"
  value       = aws_s3_bucket.backups.id
}

output "logs_bucket_name" {
  description = "Name of the logs S3 bucket"
  value       = aws_s3_bucket.logs.id
}

output "storage_class_name" {
  description = "Name of the EKS storage class"
  value       = kubernetes_storage_class.gp3.metadata[0].name
}