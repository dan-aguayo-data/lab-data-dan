# Index Maintenance Infrastructure

Automated SQL Server index maintenance using AWS Lambda, Step Functions, and EventBridge.

## Architecture

```
EventBridge (Cron) → Step Functions → Lambda → RDS SQL Server
                           ↓
                     SNS (Alerts)
```

**Workflow Steps:**
1. Collect Index Stats (fragmentation analysis)
2. Perform Maintenance (REBUILD/REORGANIZE)
3. Collect Post-Maintenance Stats (verification)
4. Send Success/Failure notification

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Docker (for building Lambda layer)
- Access to target RDS SQL Server instance

## Initial Setup

### 1. Create Database User

Run this SQL on your RDS instance:

```sql
-- Create login at server level
CREATE LOGIN index_maintenance_svc WITH PASSWORD = 'YourStrongPassword123!';

-- Switch to your database
USE EFTSURE_DEV2;

-- Create user mapped to login
CREATE USER index_maintenance_svc FOR LOGIN index_maintenance_svc;

-- Grant permissions
GRANT EXECUTE ON dbo.CollectIndexStats TO index_maintenance_svc;
GRANT EXECUTE ON dbo.PerformIndexMaintenance TO index_maintenance_svc;
GRANT SELECT, INSERT, DELETE ON dbo.IndexMaintenanceStats TO index_maintenance_svc;
GRANT SELECT, INSERT ON dbo.IndexMaintenanceLog TO index_maintenance_svc;
GRANT VIEW DATABASE STATE TO index_maintenance_svc;
```

### 2. Store Credentials in Secrets Manager

```bash
aws secretsmanager create-secret \
    --name "eftsure/dev/index-maintenance-db" \
    --description "SQL Server credentials for index maintenance Lambda" \
    --secret-string '{
        "username": "index_maintenance_svc",
        "password": "YourStrongPassword123!",
        "host": "your-rds-endpoint.ap-southeast-2.rds.amazonaws.com",
        "port": "1433",
        "database": "EFTSURE_DEV2"
    }'
```

### 3. Build Lambda Layer (pymssql)

pymssql requires compiled C libraries. Build using Docker:

```bash
# Run from project root
./build-lambda-layer.sh
```

Or manually:

```bash
docker run --rm -v $(pwd):/output amazonlinux:2023 bash -c "
    dnf install -y python3.11 python3.11-pip gcc python3.11-devel unixODBC-devel
    mkdir -p /tmp/layer/python
    pip3.11 install pymssql==2.2.11 -t /tmp/layer/python
    cd /tmp/layer && zip -r /output/lambda_layer.zip python
"
```

### 4. Create Lambda Layer in AWS

```bash
aws lambda publish-layer-version \
    --layer-name pymssql-py311 \
    --description "pymssql for Python 3.11" \
    --zip-file fileb://lambda_layer.zip \
    --compatible-runtimes python3.11
```

Update `main.tf` with the layer ARN returned.

## Deployment

### Local Development

1. Copy example files:
   ```bash
   cp my.ps1.example my.ps1
   cp dev.tfvars.example dev.tfvars
   ```

2. Edit `my.ps1` with your AWS account ID and profile

3. Edit `dev.tfvars` with your VPC, subnet, and security group details

4. Set environment variables:
   ```powershell
   . .\my.ps1
   ```

5. Initialize and deploy:
   ```bash
   terraform init
   terraform plan -var-file="dev.tfvars"
   terraform apply -var-file="dev.tfvars"
   ```

### CI/CD (GitLab)

Set these variables in GitLab CI/CD settings:

| Variable | Description |
|----------|-------------|
| `TF_VAR_aws_account_id` | AWS Account ID |
| `AWS_ACCESS_KEY_ID` | AWS credentials |
| `AWS_SECRET_ACCESS_KEY` | AWS credentials |

See `.gitlab-ci.yml` for pipeline configuration.

## Configuration

### Tables to Maintain

Edit `include_tables` in your tfvars file:

```hcl
# Only these tables
include_tables = "Suppliers,WHITELIST,Orders"

# Or exclude specific tables (process everything else)
include_tables = ""
exclude_tables = "AuditLog,TempData"
```

### Schedule

Default: Daily at 3 AM AEDT (5 PM UTC previous day)

```hcl
# Every day at 3 AM AEDT
schedule_expression = "cron(0 17 * * ? *)"

# Every Sunday at 2 AM
schedule_expression = "cron(0 16 ? * SUN *)"

# Every 6 hours
schedule_expression = "rate(6 hours)"
```

### Timeouts

```hcl
procedure_timeout_seconds = 300  # 5 minutes - kills long-running queries
lambda_timeout_seconds    = 360  # 6 minutes - Lambda execution limit
```

## Monitoring

### Check Step Functions Execution

AWS Console → Step Functions → index-maintenance-dev-workflow → Executions

### Check Lambda Logs

```bash
aws logs tail /aws/lambda/index-maintenance-dev-executor --follow
```

### Query Maintenance History

```sql
SELECT TOP 100 * 
FROM dbo.IndexMaintenanceLog 
ORDER BY LogDate DESC;
```

### Query Current Fragmentation

```sql
SELECT * 
FROM dbo.IndexMaintenanceStats 
ORDER BY avg_fragmentation_in_percent DESC;
```

## Manual Execution

Trigger the workflow manually:

```bash
aws stepfunctions start-execution \
    --state-machine-arn "arn:aws:states:ap-southeast-2:123456789012:stateMachine:index-maintenance-dev-workflow"
```

## Troubleshooting

### Lambda Cannot Connect to RDS

1. Verify Lambda is in the same VPC as RDS
2. Check security group allows port 1433 from Lambda's security group
3. Verify subnets have route to RDS

### Timeout Errors

1. Check `procedure_timeout_seconds` - increase if needed
2. Review which indexes are being processed - reduce scope with `include_tables`
3. Check RDS CPU/memory during maintenance

### Permission Errors

Verify the database user has all required permissions:

```sql
-- Check permissions
SELECT dp.permission_name, o.name AS object_name
FROM sys.database_permissions dp
JOIN sys.objects o ON dp.major_id = o.object_id
JOIN sys.database_principals pr ON dp.grantee_principal_id = pr.principal_id
WHERE pr.name = 'index_maintenance_svc';
```

## File Structure

```
terraform-index-maintenance/
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Variable definitions
├── dev.tfvars.example      # Example dev environment values
├── my.ps1.example          # Example local env vars script
├── .gitignore
├── README.md
├── build-lambda-layer.sh   # Lambda layer build script
├── .gitlab-ci.yml          # GitLab CI/CD pipeline
└── lambda/
    ├── index_maintenance.py    # Lambda function code
    └── requirements.txt        # Python dependencies
```
