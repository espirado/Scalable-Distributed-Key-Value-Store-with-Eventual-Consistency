# Backup Policies

## Data Selection

### 1. Included Resources
- EBS volumes with tag `Backup = true`
- Stateful components
- Configuration data
- Metadata stores

### 2. Retention Rules

#### Daily Backups
- 30-day retention
- Operational recovery
- Quick restore capability

#### Weekly Backups
- 90-day retention
- Point-in-time recovery
- Intermediate storage

#### Monthly Backups
- 365-day retention
- Compliance requirements
- Secondary copy with extended retention

### 3. Backup Windows
| Type    | Schedule          | Window Duration |
|---------|------------------|-----------------|
| Daily   | 00:00 UTC        | 4 hours        |
| Weekly  | Sunday 00:00 UTC | 6 hours        |
| Monthly | 1st 00:00 UTC    | 8 hours        |