# SQL Server Backup Export Pipeline

Automated pipeline that restores SQL Server `.bak` files from S3, exports tables as gzipped CSVs, and uploads to another S3 bucket for downstream processing (e.g., Snowflake ingestion).

## Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────────────────────────────┐      ┌─────────────┐
│  EventBridge│      │    Step      │      │          ECS Fargate Task           │      │     S3      │
│  (Schedule) │─────▶│  Functions   │─────▶│  ┌─────────────────────────────┐   │─────▶│  (Exports)  │
└─────────────┘      └──────────────┘      │  │     SQL Server Container     │   │      └─────────────┘
                            │              │  │  1. Download .bak from S3    │   │             │
                            │              │  │  2. Restore database         │   │             │
                            ▼              │  │  3. BCP export tables        │   │             ▼
                     ┌──────────────┐      │  │  4. Gzip & upload to S3      │   │      ┌─────────────┐
                     │     SNS      │      │  └─────────────────────────────┘   │      │  Snowflake  │
                     │ (Alerts)     │      └─────────────────────────────────────┘      │  (Consumer) │
                     └──────────────┘                                                   └─────────────┘
```

## Prerequisites

- **Docker Desktop** - Running and logged in
- **AWS CLI v2** - Configured with appropriate credentials
- **Terraform** - v1.0+
- **PowerShell** - 5.1+ (Windows) or PowerShell Core (macOS/Linux)

## Quick Start

### 1. Clone and Configure

```powershell
git clone <repo-url>
cd aws-mssql-ecs
```

### 2. Configure Environment Variables

Edit `deploy.ps1` and update the environment-specific section:

```powershell
# ============================================
# ENVIRONMENT-SPECIFIC CONFIG (not in git)
# ============================================
$env:TF_VAR_aws_region         = "ap-southeast-2"      # Your AWS region
$env:TF_VAR_vpc_id             = "vpc-xxxxxxxxx"       # Your VPC ID
$env:TF_VAR_private_subnet_ids = '["subnet-xxxxx"]'    # Your private subnet(s)
$env:TF_VAR_alert_email        = "you@company.com"     # Alert recipient
```

### 3. Configure terraform.tfvars

Edit `terraform.tfvars` for your database and S3 configuration:

```hcl
# Project
project_name = "sql-export"
environment  = "dev"

# S3 Buckets
backup_bucket_name = "your-backup-bucket"     # Where .bak files are stored
backup_prefix      = "backups/"               # Prefix within bucket
export_bucket_name = "your-export-bucket"     # Where CSVs will be written
export_prefix      = "exports/"               # Prefix for exports

# Database
database_name    = "YourDatabaseName"
tables_to_export = ""                         # Empty = all tables, or "dbo.Table1,dbo.Table2"

# Schedule (UTC)
schedule_expression = "cron(0 2 * * ? *)"     # 2 AM UTC daily

# Resources (adjust based on backup size)
fargate_cpu               = 4096              # 4 vCPUs
fargate_memory            = 16384             # 16 GB
fargate_ephemeral_storage = 200               # GB (must be > 2x backup size)
```

### 4. Deploy Infrastructure

```powershell
# Preview changes
.\deploy.ps1 plan

# Deploy (creates all AWS resources)
.\deploy.ps1 apply
```

### 5. Set SQL Server Password

The SA password is stored securely in AWS Secrets Manager. Set it with:

```powershell
.\deploy.ps1 set-password
# Enter your password when prompted
```

**Password Requirements:**
- At least 8 characters
- Mix of uppercase, lowercase, numbers, and special characters

### 6. Build and Push Docker Image

```powershell
# Build the image
cd docker
docker build -t sql-export:latest .
cd ..

# Login to ECR
$ECR_URL = terraform output -raw ecr_repository_url
$ECR_REGISTRY = $ECR_URL.Split('/')[0]
$token = (aws ecr get-login-password --region ap-southeast-2).Trim()
docker login --username AWS --password $token $ECR_REGISTRY

# Tag and push
docker tag sql-export:latest ${ECR_URL}:latest
docker push ${ECR_URL}:latest
```

Or use the deploy script:
```powershell
.\deploy.ps1 build
```

### 7. Confirm SNS Subscription

Check your email and confirm the SNS subscription for alerts.

### 8. Test the Pipeline

```powershell
# Trigger a manual run
.\deploy.ps1 trigger

# Watch logs in real-time
.\deploy.ps1 logs
```

## Deployment Commands

| Command | Description |
|---------|-------------|
| `.\deploy.ps1 plan` | Preview Terraform changes |
| `.\deploy.ps1 apply` | Deploy/update infrastructure |
| `.\deploy.ps1 build` | Build and push Docker image |
| `.\deploy.ps1 set-password` | Set SA password in Secrets Manager |
| `.\deploy.ps1 trigger` | Manually trigger pipeline |
| `.\deploy.ps1 logs` | Tail CloudWatch logs |
| `.\deploy.ps1 destroy` | Tear down all resources |

## File Structure

```
aws-mssql-ecs/
├── deploy.ps1                    # Main deployment script
├── terraform.tfvars              # Your configuration (edit this)
├── global_variables.tf           # Variable definitions
├── svc_variables.tf              # Service-specific variables
├── providers.tf                  # AWS provider config
├── backend.tf                    # Terraform state config
├── outputs.tf                    # Output values
│
├── aws_ecs.tf                    # ECS cluster & task definition
├── aws_ecr.tf                    # Container registry
├── aws_iam.tf                    # IAM roles & policies
├── aws_s3.tf                     # S3 buckets
├── aws_sec_manager.tf            # Secrets Manager
├── aws_step_function.tf          # Step Functions state machine
├── aws_eventbridge.tf            # Scheduled trigger
├── aws_sns.tf                    # Notifications & alerts
├── aws_cloudwatch.tf             # Logs & dashboard
│
└── docker/
    ├── Dockerfile                # SQL Server container image
    └── scripts/
        └── entrypoint.sh         # Main orchestration script
```

## How It Works

1. **EventBridge** triggers the pipeline on schedule (or manually)
2. **Step Functions** starts an ECS Fargate task
3. **ECS Task**:
   - Starts SQL Server
   - Finds the latest `.bak` file in the source S3 bucket
   - Downloads and restores the database
   - Exports specified tables using BCP
   - Gzips and uploads CSVs to the destination S3 bucket
4. **Step Functions** sends success/failure notifications via SNS

## Output Structure

Exports are organized by execution ID:

```
s3://your-export-bucket/exports/
├── abc12345-6789-0def-ghij-klmnopqrstuv/
│   ├── dbo_Customers.csv.gz
│   ├── dbo_Orders.csv.gz
│   └── dbo_Products.csv.gz
├── def67890-1234-5abc-defg-hijklmnopqrs/
│   ├── dbo_Customers.csv.gz
│   └── ...
```

## Monitoring

### CloudWatch Dashboard

Access via AWS Console or use the URL from:
```powershell
terraform output cloudwatch_dashboard_url
```

### Logs

```powershell
# Real-time logs
.\deploy.ps1 logs

# Or via AWS CLI
aws logs tail /aws/ecs/sql-export --follow
```

### Alerts

Pipeline failures trigger SNS notifications to your configured email.

## Troubleshooting

### Task fails immediately

Check CloudWatch logs for startup errors:
```powershell
.\deploy.ps1 logs
```

Common issues:
- **Password mismatch**: Run `.\deploy.ps1 set-password` again
- **Missing .bak file**: Check source S3 bucket and prefix
- **Insufficient storage**: Increase `fargate_ephemeral_storage`

### BCP export fails

- Check table names in `tables_to_export`
- Verify database name matches backup
- Look for certificate errors (should be auto-handled)

### S3 access denied

- Verify bucket names in `terraform.tfvars`
- Check IAM policies in `aws_iam.tf`
- For cross-account buckets, add bucket policy

### Image not updated

After code changes:
```powershell
.\deploy.ps1 build
```

Verify new digest:
```powershell
aws ecr describe-images --repository-name sql-export --image-ids imageTag=latest --query 'imageDetails[0].imageDigest' --output text
```

## Cross-Account S3 Access

If your source/destination S3 buckets are in a different AWS account:

1. **Your account**: IAM role already has permissions (via `aws_iam.tf`)

2. **Other account**: Add bucket policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "AWS": "arn:aws:iam::YOUR_ACCOUNT_ID:role/sql-export-ecs-task"
    },
    "Action": ["s3:GetObject", "s3:ListBucket", "s3:PutObject"],
    "Resource": [
      "arn:aws:s3:::their-bucket",
      "arn:aws:s3:::their-bucket/*"
    ]
  }]
}
```

## Customization

### Export All Tables vs Specific Tables

```hcl
# All tables
tables_to_export = ""

# Specific tables
tables_to_export = "dbo.Customers,dbo.Orders,dbo.Products"
```

### Change Schedule

```hcl
# Daily at 2 AM UTC
schedule_expression = "cron(0 2 * * ? *)"

# Every 6 hours
schedule_expression = "rate(6 hours)"

# Weekdays only at 3 AM UTC
schedule_expression = "cron(0 3 ? * MON-FRI *)"
```

### Adjust Resources

For larger databases, increase Fargate resources:

```hcl
fargate_cpu               = 4096    # 4 vCPUs (max: 16384)
fargate_memory            = 30720   # 30 GB (max depends on CPU)
fargate_ephemeral_storage = 200     # GB (max: 200)
```

## Multiple Deployments

To run multiple pipelines (e.g., different databases), use Terraform workspaces:

```powershell
# Create workspace for each database
terraform workspace new database-a
terraform workspace new database-b

# Deploy with different configs
terraform workspace select database-a
.\deploy.ps1 apply  # Uses database-a.tfvars

terraform workspace select database-b
.\deploy.ps1 apply  # Uses database-b.tfvars
```

## Security Notes

- **SA Password**: Stored in AWS Secrets Manager, never in code
- **No hardcoded credentials**: All secrets injected at runtime
- **Private subnets**: ECS tasks run in private subnets with NAT
- **Least privilege**: IAM roles scoped to minimum required permissions
- **Encryption**: S3 server-side encryption enabled

## Cost Estimate

- **Fargate**: ~$0.04/vCPU/hour + ~$0.004/GB/hour (only while running)
- **S3**: Storage + transfer costs
- **Secrets Manager**: ~$0.40/secret/month
- **CloudWatch**: Logs storage + dashboard

For a daily 30-minute job with 4 vCPU / 16 GB: ~$15-30/month

## Cleanup

To remove all resources:

```powershell
.\deploy.ps1 destroy
```

**Note**: This will delete:
- ECS cluster and task definition
- ECR repository (including images)
- S3 export bucket (if created by Terraform)
- All CloudWatch logs
- Secrets Manager secret

## Support

For issues or questions, check:
1. CloudWatch logs for detailed error messages
2. Step Functions execution history for state transitions
3. ECS task details for container exit codes