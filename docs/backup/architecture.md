# Backup Architecture

## Components

### 1. AWS Backup Vault
- Encrypted storage location
- KMS encryption enabled
- Region-specific storage
- Access controls

### 2. Backup Plans
#### Daily Backups
- Schedule: Midnight UTC
- Retention: 30 days
- Purpose: Operational recovery

#### Weekly Backups
- Schedule: Sunday midnight UTC
- Retention: 90 days
- Purpose: Point-in-time recovery

#### Monthly Backups
- Schedule: 1st of month UTC
- Retention: 365 days
- Purpose: Compliance and archival

### 3. IAM Configuration
- Dedicated backup role
- Service-role policies
- Least privilege access