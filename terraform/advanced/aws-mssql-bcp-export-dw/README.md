# MSSQL BCP Multi-Region Export Pipeline

Terraform infrastructure for exporting MSSQL tables from US and AU databases to S3 using BCP commands, orchestrated by Step Functions.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Step Functions                          │
│  ┌──────────────┐        ┌──────────────┐                  │
│  │   US Export  │        │   AU Export  │                  │
│  └──────┬───────┘        └──────┬───────┘                  │
│         │                       │                           │
│         ▼                       ▼                           │
│  ┌──────────────┐        ┌──────────────┐                  │
│  │ ECS Task (US)│        │ ECS Task (AU)│                  │
│  └──────┬───────┘        └──────┬───────┘                  │
└─────────┼────────────────────────┼─────────────────────────┘
          │                        │
          ▼                        ▼
   ┌─────────────┐          ┌─────────────┐
   │ MSSQL (US)  │          │ MSSQL (AU)  │
   │ RDS/EC2     │          │ RDS/EC2     │
   └─────────────┘          └─────────────┘
          │                        │
          └────────────┬───────────┘
                       ▼
              ┌─────────────────┐
              │   S3 Bucket     │
              │  /us/timestamp/ │
              │  /au/timestamp/ │
              └─────────────────┘
```

## Features

- **Multi-Region Support**: Separate ECS tasks for US and AU databases
- **VPC Networking**: Tasks run in private subnets with VPN access
- **Secure Credentials**: Secrets Manager for database credentials
- **Orchestration**: Step Functions with parallel or sequential execution
- **Monitoring**: CloudWatch logs, metrics, and dashboards
- **Flexibility**: Configurable tables, schedules, and regions

## Prerequisites

1. **VPC Setup**: Existing VPC with private subnets that have VPN connectivity
2. **Database Access**: MSSQL instances accessible from VPC (port 1433)
3. **AWS Resources**: S3 bucket, DynamoDB table for Terraform state
4. **Docker**: For building and pushing the MSSQL BCP image

## Quick Start

### 1. Configure Secrets (PowerShell)

Create `load-env.ps1` with your sensitive credentials:

```powershell
# US Database Credentials
$env:TF_VAR_us_mssql_host = "us-db.example.com"
$env:TF_VAR_us_mssql_user = "db_export_user"
$env:TF_VAR_us_mssql_password = "SecurePassword123!"

# AU Database Credentials  
$env:TF_VAR_au_mssql_host = "au-db.example.com"
$env:TF_VAR_au_mssql_user = "db_export_user"
$env:TF_VAR_au_mssql_password = "SecurePassword456!"

# VPC Configuration
$env:TF_VAR_vpc_id = "vpc-xxxxx"
$env:TF_VAR_private_subnet_ids = '["subnet-xxxxx", "subnet-yyyyy"]'
$env:TF_VAR_alert_email = "yourteam@example.com"
```

Load the environment:
```powershell
.\load-env.ps1
```

### 2. Configure Terraform Variables

Edit `terraform.tfvars`:

```hcl
# Project Configuration
project_name    = "mssql-bcp-export"
environment     = "prod"
aws_region      = "ap-southeast-2"  # Primary region for infrastructure
cost_center     = "data-engineering"

# S3 Configuration
export_bucket_name = "your-company-mssql-exports"
export_prefix      = "exports/"
data_source_name   = "admin_portal"  # Team/source name for S3 organization

# US Database Configuration
us_database_name    = "ProductionDB"
us_tables_to_export = "dbo.Orders,dbo.Customers,dbo.Products"  # or empty for all

# AU Database Configuration
au_database_name    = "ProductionDB"
au_tables_to_export = "dbo.Orders,dbo.Customers,dbo.Products"  # or empty for all

# Execution Schedule
schedule_expression = "cron(0 2 * * ? *)"  # 2 AM UTC daily

# Performance Tuning
fargate_cpu                = 2048   # 2 vCPUs
fargate_memory             = 8192   # 8 GB
fargate_ephemeral_storage  = 100    # GB
task_timeout_seconds       = 7200   # 2 hours
```

### 3. Build and Deploy

```bash
# Initialize Terraform
terraform init

# Build and push Docker image
cd docker
./build-and-push.sh

# Deploy infrastructure
cd ..
terraform plan
terraform apply
```

### 4. Manual Execution

Trigger via AWS Console, CLI, or API:

```bash
# Start both US and AU exports
aws stepfunctions start-execution \
  --state-machine-arn arn:aws:states:ap-southeast-2:ACCOUNT:stateMachine:mssql-bcp-export \
  --name "manual-$(date +%Y%m%d-%H%M%S)"
```

## Networking Requirements

### VPN Access
Since your MSSQL instances are only accessible via VPN, the ECS tasks must:

1. **Run in VPC Private Subnets**: Configure `private_subnet_ids` in your VPC
2. **Security Group Rules**: Allow outbound to MSSQL port 1433
3. **VPN Connectivity**: Subnets must have routes to VPN gateway

### Security Group Configuration

The Terraform automatically creates:
- **Egress to MSSQL**: Port 1433 to your database hosts
- **Egress to AWS Services**: S3, Secrets Manager, CloudWatch (via VPC endpoints or internet)

## S3 Output Structure

```
s3://your-bucket/exports/
├── admin_portal/              # Data source/team name
│   ├── us/                    # Region
│   │   └── ProductionDB/      # Database name
│   │       └── export-20260204-120000/  # Timestamp
│   │           ├── dbo_Orders.csv.gz
│   │           ├── dbo_Customers.csv.gz
│   │           └── dbo_Products.csv.gz
│   └── au/                    # Region
│       └── ProductionDB/      # Database name
│           └── export-20260204-120000/  # Timestamp
│               ├── dbo_Orders.csv.gz
│               ├── dbo_Customers.csv.gz
│               └── dbo_Products.csv.gz
└── customer_api/              # Another data source (example)
    ├── us/
    │   └── CustomerDB/
    └── au/
        └── CustomerDB/
```

The hierarchy is: `bucket/prefix/data_source/region/database/timestamp/tables.csv.gz`

This structure allows you to:
- Organize exports by team or data source
- Separate regions clearly
- Handle multiple databases from the same source
- Track historical exports by timestamp

## Monitoring

### CloudWatch Dashboards
Automatic dashboard showing:
- Task execution duration
- Rows exported per region
- Failure rates
- Cost metrics

### Alerts
SNS notifications for:
- ✅ Successful exports
- 🚨 Failed exports
- ⚠️ Partial failures

### Logs
Structured logs in CloudWatch:
- `/aws/ecs/mssql-bcp-export-us`
- `/aws/ecs/mssql-bcp-export-au`
- `/aws/stepfunctions/mssql-bcp-export`

## Troubleshooting

### Connection Issues
```bash
# Check ECS task logs
aws logs tail /aws/ecs/mssql-bcp-export-us --follow

# Verify secrets
aws secretsmanager get-secret-value --secret-id mssql-bcp-export/us/credentials

# Test network connectivity (from bastion in same VPC)
telnet us-db.example.com 1433
```

### Permission Issues
Ensure IAM roles have:
- S3: `PutObject`, `GetObject`
- Secrets Manager: `GetSecretValue`
- CloudWatch: `PutLogEvents`, `PutMetricData`

### BCP Failures
- Check table names match exactly (case-sensitive in Linux)
- Verify user has SELECT permissions on all tables
- Review error logs: `/tmp/exports/{table}_errors.log`

## Cost Optimization

- Use FARGATE_SPOT for non-critical workloads (50-70% cheaper)
- Adjust `fargate_cpu` and `fargate_memory` based on actual usage
- Enable S3 Intelligent-Tiering for exports
- Set CloudWatch log retention to 7-14 days for cost control

## Security Best Practices

1. **Never commit `load-env.ps1`** (added to `.gitignore`)
2. **Rotate credentials** quarterly using Secrets Manager rotation
3. **Use least privilege** IAM roles
4. **Enable encryption**: S3 (AES-256), Secrets Manager (KMS)
5. **VPC Flow Logs**: Monitor network traffic to databases

## Files Structure

```
.
├── README.md
├── backend.tf                  # S3 backend configuration
├── providers.tf                # AWS provider setup
├── global_variables.tf         # Common variables
├── us_variables.tf             # US-specific variables
├── au_variables.tf             # AU-specific variables
├── terraform.tfvars            # Variable values (safe to commit)
├── load-env.ps1                # Secrets (NEVER commit)
├── aws_s3.tf                   # S3 bucket for exports
├── aws_ecr.tf                  # ECR repository for Docker image
├── aws_ecs_us.tf               # US ECS cluster and tasks
├── aws_ecs_au.tf               # AU ECS cluster and tasks
├── aws_iam.tf                  # IAM roles and policies
├── aws_sec_manager.tf          # Secrets Manager for credentials
├── aws_step_function.tf        # Step Functions orchestration
├── aws_cloudwatch.tf           # Logs, metrics, dashboards
├── aws_sns.tf                  # SNS topics for alerts
├── outputs.tf                  # Terraform outputs
└── docker/
    ├── Dockerfile              # MSSQL BCP container image
    ├── build-and-push.sh       # Build script
    └── scripts/
        └── entrypoint.sh       # BCP export logic
```

## License

Internal Eftsure project - All rights reserved
