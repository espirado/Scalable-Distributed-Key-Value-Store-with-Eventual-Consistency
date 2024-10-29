output "backup_vault_arn" {
  description = "ARN of the backup vault"
  value       = aws_backup_vault.main.arn
}

output "backup_vault_name" {
  description = "Name of the backup vault"
  value       = aws_backup_vault.main.name
}

output "backup_plans" {
  description = "Map of backup plan IDs"
  value = {
    daily   = aws_backup_plan.daily.id
    weekly  = aws_backup_plan.weekly.id
    monthly = aws_backup_plan.monthly.id
  }
}