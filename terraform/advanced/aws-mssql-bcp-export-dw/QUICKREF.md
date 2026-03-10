# Quick Reference - MSSQL BCP Export Pipeline

## Common Commands

### Deployment
```bash
# Load credentials
.\load-env.ps1

# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Build and push Docker image
cd docker && ./build-and-push.sh
```

### Manual Execution
```bash
# Start execution via CLI
aws stepfunctions start-execution \
  --state-machine-arn $(terraform output -raw step_function_arn) \
  --name manual-$(date +%Y%m%d-%H%M%S)

# Check execution status
aws stepfunctions describe-execution \
  --execution-arn arn:aws:states:REGION:ACCOUNT:execution:STATE_MACHINE:EXECUTION_NAME
```

### Monitoring
```bash
# Tail US export logs
aws logs tail /aws/ecs/mssql-bcp-export-us --follow

# Tail AU export logs
aws logs tail /aws/ecs/mssql-bcp-export-au --follow

# Tail Step Functions logs
aws logs tail /aws/vendedlogs/states/mssql-bcp-export --follow

# List recent executions
aws stepfunctions list-executions \
  --state-machine-arn $(terraform output -raw step_function_arn) \
  --max-results 10
```

### S3 Management
```bash
# List exports
aws s3 ls s3://YOUR-BUCKET/exports/ --recursive

# Download specific export
aws s3 cp s3://YOUR-BUCKET/exports/us/export-TIMESTAMP/ . --recursive

# Check bucket size
aws s3 ls s3://YOUR-BUCKET/exports/ --recursive --summarize --human-readable
```

### Secrets Management
```bash
# View US credentials
aws secretsmanager get-secret-value \
  --secret-id mssql-bcp-export/us/credentials

# View AU credentials
aws secretsmanager get-secret-value \
  --secret-id mssql-bcp-export/au/credentials

# Update US password
aws secretsmanager update-secret \
  --secret-id mssql-bcp-export/us/credentials \
  --secret-string '{"host":"...","port":1433,"username":"...","password":"NEW_PASSWORD","database":"..."}'
```

### Debugging
```bash
# Check ECS task status
aws ecs list-tasks --cluster mssql-bcp-export

# Describe running task
aws ecs describe-tasks \
  --cluster mssql-bcp-export \
  --tasks TASK_ARN

# Get last stopped task
aws ecs list-tasks \
  --cluster mssql-bcp-export \
  --desired-status STOPPED \
  --max-results 1

# Test Docker image locally
docker run --rm \
  -e REGION=test \
  -e DATABASE_NAME=TestDB \
  -e DB_CREDENTIALS='{"host":"localhost","port":1433,"username":"sa","password":"YourPassword"}' \
  -e OUTPUT_BUCKET=test-bucket \
  -e OUTPUT_PREFIX=test/ \
  -e TABLES=dbo.TestTable \
  ECR_URL:latest
```

## Configuration Files

| File | Purpose | Sensitive? |
|------|---------|------------|
| `terraform.tfvars` | Non-sensitive config | No |
| `load-env.ps1` | Database credentials | **YES - Never commit** |
| `backend.tf` | Terraform state config | No |
| `docker/scripts/entrypoint.sh` | Export logic | No |

## Environment Variables

### Required (from load-env.ps1)
- `TF_VAR_us_mssql_host`
- `TF_VAR_us_mssql_user`
- `TF_VAR_us_mssql_password`
- `TF_VAR_au_mssql_host`
- `TF_VAR_au_mssql_user`
- `TF_VAR_au_mssql_password`

### Optional (from terraform.tfvars)
- `TF_VAR_vpc_id`
- `TF_VAR_private_subnet_ids`
- `TF_VAR_alert_email`

## Resource Names

| Resource | Name Pattern |
|----------|--------------|
| ECS Cluster | `mssql-bcp-export` |
| US Task Definition | `mssql-bcp-export-us-export` |
| AU Task Definition | `mssql-bcp-export-au-export` |
| Step Function | `mssql-bcp-export` |
| ECR Repository | `mssql-bcp-export-bcp` |
| S3 Bucket | `YOUR_BUCKET/exports/` |
| CloudWatch Log Groups | `/aws/ecs/mssql-bcp-export-{us|au}` |

## Default Configurations

| Setting | Default Value |
|---------|---------------|
| Schedule | `cron(0 2 * * ? *)` (2 AM UTC) |
| Execution Mode | `parallel` |
| Fargate CPU | 2048 (2 vCPUs) |
| Fargate Memory | 8192 MB (8 GB) |
| Ephemeral Storage | 100 GB |
| Task Timeout | 7200s (2 hours) |
| Log Retention | 30 days |
| BCP Batch Size | 10000 rows |

## S3 Output Structure
```
s3://YOUR-BUCKET/
└── exports/
    └── admin_portal/           # Data source/team
        ├── us/                 # Region
        │   └── ProductionDB/   # Database
        │       └── export-YYYYMMDD-HHMMSS/  # Timestamp
        │           ├── dbo_Table1.csv.gz
        │           └── dbo_Table2.csv.gz
        └── au/                 # Region
            └── ProductionDB/   # Database
                └── export-YYYYMMDD-HHMMSS/  # Timestamp
                    ├── dbo_Table1.csv.gz
                    └── dbo_Table2.csv.gz
```

Path format: `bucket/prefix/data_source/region/database/timestamp/table.csv.gz`

## Port Requirements

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| ECS Tasks | US MSSQL | 1433 | TCP | Database connection |
| ECS Tasks | AU MSSQL | 1433 | TCP | Database connection |
| ECS Tasks | AWS Services | 443 | TCP | S3, Secrets Manager, CloudWatch |

## IAM Roles

| Role | Purpose |
|------|---------|
| `mssql-bcp-export-ecs-execution` | Pull images, fetch secrets, write logs |
| `mssql-bcp-export-ecs-task` | S3 upload, CloudWatch metrics |
| `mssql-bcp-export-sfn-execution` | Run ECS tasks, send SNS |
| `mssql-bcp-export-eventbridge` | Trigger Step Functions |

## Cost Estimates (Monthly)

Based on default configuration running daily:

| Service | Usage | Est. Cost |
|---------|-------|-----------|
| Fargate (2 vCPU, 8GB) | ~1 hour/day | $15-20 |
| S3 Storage | ~100 GB | $2-3 |
| CloudWatch Logs | ~5 GB | $2-3 |
| Step Functions | ~30 executions | $0.25 |
| Secrets Manager | 2 secrets | $0.80 |
| Data Transfer | ~50 GB | $4-5 |
| **Total** | | **~$25-35/month** |

*Note: Costs vary based on data size and execution time*

## Support Contacts

- **CloudWatch Logs**: First place to check for errors
- **AWS Console**: Step Functions for execution history
- **Documentation**: README.md, DEPLOYMENT.md
- **Team**: data-engineering@eftsure.com
