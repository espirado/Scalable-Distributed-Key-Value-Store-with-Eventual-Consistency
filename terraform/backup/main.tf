locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# AWS Backup Vault
resource "aws_backup_vault" "main" {
  name        = "${local.name_prefix}-vault"
  kms_key_arn = var.kms_key_arn

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-vault"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

# IAM Role for AWS Backup
resource "aws_iam_role" "backup" {
  name = "${local.name_prefix}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-backup-role"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

# IAM Policy for AWS Backup
resource "aws_iam_role_policy_attachment" "backup" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup.name
}

# Backup Plans
resource "aws_backup_plan" "daily" {
  name = "${local.name_prefix}-daily"

  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.main.name
    schedule          = var.backup_schedule["daily"]
    
    lifecycle {
      delete_after = var.backup_retention_days["daily"]
    }

    recovery_point_tags = {
      Environment = var.environment
      Project     = var.project_name
      BackupType  = "daily"
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-daily"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

resource "aws_backup_plan" "weekly" {
  name = "${local.name_prefix}-weekly"

  rule {
    rule_name         = "weekly"
    target_vault_name = aws_backup_vault.main.name
    schedule          = var.backup_schedule["weekly"]
    
    lifecycle {
      delete_after = var.backup_retention_days["weekly"]
    }

    recovery_point_tags = {
      Environment = var.environment
      Project     = var.project_name
      BackupType  = "weekly"
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-weekly"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

resource "aws_backup_plan" "monthly" {
  name = "${local.name_prefix}-monthly"

  rule {
    rule_name         = "monthly"
    target_vault_name = aws_backup_vault.main.name
    schedule          = var.backup_schedule["monthly"]
    
    lifecycle {
      delete_after = var.backup_retention_days["monthly"]
    }

    recovery_point_tags = {
      Environment = var.environment
      Project     = var.project_name
      BackupType  = "monthly"
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.main.arn
      lifecycle {
        delete_after = var.backup_retention_days["monthly"] * 2
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-monthly"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

# Selection for EBS Volumes
resource "aws_backup_selection" "ebs" {
  name = "${local.name_prefix}-ebs"
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.daily.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "true"
  }
}
