# Terraform - ECS dbt Core Infrastructure

This Terraform configuration deploys the AWS infrastructure for running dbt Core on ECS Fargate.

## What Gets Created

- **ECR Repository**: Docker image storage
- **ECS Cluster**: Fargate cluster for running tasks
- **Task Definition**: dbt container configuration
- **Step Functions**: Orchestration with retry/notifications
- **EventBridge Scheduler**: Scheduled job triggers
- **VPC/Networking**: Isolated network for tasks
- **IAM Roles**: Execution and task roles
- **S3 Bucket**: dbt artifacts storage
- **SNS Topic**: Alert notifications
- **CloudWatch Logs**: Container logging

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform >= 1.5.0
3. S3 bucket for Terraform state (already exists)
4. DynamoDB table for state locking (already exists)
5. Secrets Manager secret with Snowflake private key (already exists)

## Quick Start

### Step 1: Load Environment Variables

```powershell
# Copy the example and edit with your values
Copy-Item load-env.ps1.example load-env.ps1

# Edit load-env.ps1 with your actual values
notepad load-env.ps1

# Load the variables
. .\load-env.ps1
```

### Step 2: Initialize Terraform

```powershell
terraform init
```

### Step 3: Review Plan

```powershell
terraform plan
```

### Step 4: Apply

```powershell
terraform apply
```

## Environment Variables Reference

These must be set via `load-env.ps1` before running Terraform:

| Variable | Description | Example |
|----------|-------------|---------|
| `TF_VAR_dbt_snowflake_account` | Snowflake account ID | `BXNRJRX-XQ57619` |
| `TF_VAR_dbt_snowflake_user` | Snowflake service user | `SVC_DATA_DBT` |
| `TF_VAR_dbt_snowflake_role` | Snowflake role | `SVC_ROLE_DBT_RW` |
| `TF_VAR_dbt_database` | Target database | `STAGING_DEV` |
| `TF_VAR_dbt_schema` | Target schema | `DEV` |
| `TF_VAR_dbt_warehouse` | Compute warehouse | `EFT_DATA_DBT_DEFAULT` |
| `TF_VAR_snowflake_secret_name` | Secrets Manager name | `data/snowflake/svc_dbt_rsa1_private` |
| `TF_VAR_alert_email` | SNS alert email | `you@company.com` |
| `TF_VAR_terraform_state_bucket` | State S3 bucket | `eft-data-terraform-backend` |
| `TF_VAR_terraform_dynamodb_table` | Lock table | `terraform-state-lock-data-dbt-core` |

## File Structure

```
terraform-ecs-dbt/
├── main.tf                 # Provider, backend, locals
├── variables.tf            # Variable definitions
├── terraform.tfvars        # Non-sensitive defaults
├── load-env.ps1            # Sensitive values (gitignored)
├── load-env.ps1.example    # Template for load-env.ps1
├── network.tf              # VPC, subnets, security groups
├── ecr.tf                  # ECR repository
├── ecs.tf                  # ECS cluster, task definition
├── iam.tf                  # IAM roles and policies
├── secrets.tf              # Secrets Manager references
├── s3.tf                   # Artifacts bucket
├── logs.tf                 # CloudWatch log groups
├── step_functions.tf       # Step Functions state machine
├── scheduler.tf            # EventBridge, SNS, DLQ
├── outputs.tf              # Output values
└── .gitignore              # Ignores sensitive files
```

## After Deployment

### Get ECR Repository URL

```powershell
terraform output ecr_repository_url
```

### Get Step Functions ARN (for manual runs)

```powershell
terraform output step_function_arn
```

### Test a Manual Run

```powershell
terraform output manual_run_command
```

## Adding/Modifying Jobs

Edit `terraform.tfvars` to add or modify scheduled jobs:

```hcl
dbt_jobs = {
  my_new_job = {
    description         = "Run my new model"
    dbt_command         = "run"
    dbt_select          = "my_new_model"
    schedule_expression = "cron(0 21 * * ? *)"
    schedule_enabled    = true
    timeout_minutes     = 30
  }
}
```

Then apply:

```powershell
terraform apply
```

## Security Notes

- `load-env.ps1` is gitignored - NEVER commit it
- Sensitive values are marked as `sensitive = true`
- State file contains sensitive data - S3 bucket has encryption
- Private keys stay in Secrets Manager, never in Terraform
