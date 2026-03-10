# Deployment Guide - MSSQL BCP Multi-Region Export

This guide walks you through deploying the MSSQL BCP export pipeline from scratch.

## Prerequisites Checklist

- [ ] **AWS Account** with appropriate permissions
- [ ] **VPC with VPN connectivity** to MSSQL instances
- [ ] **Private subnets** with routes to VPN gateway
- [ ] **MSSQL credentials** for US and AU databases
- [ ] **S3 bucket** for Terraform state (or create new)
- [ ] **DynamoDB table** for state locking (or create new)
- [ ] **Docker installed** on your local machine
- [ ] **Terraform >= 1.0** installed
- [ ] **AWS CLI v2** configured with credentials
- [ ] **PowerShell** (for load-env.ps1)

## Step 1: Clone and Configure

### 1.1 Navigate to Project Directory
```bash
cd mssql-bcp-export
```

### 1.2 Configure Backend (backend.tf)
Update the S3 bucket and DynamoDB table for Terraform state:

```hcl
terraform {
  backend "s3" {
    bucket         = "YOUR-STATE-BUCKET"        # CHANGE THIS
    key            = "mssql_bcp_export/terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "YOUR-LOCK-TABLE"          # CHANGE THIS
  }
}
```

### 1.3 Configure Variables (terraform.tfvars)
Edit `terraform.tfvars` with your settings:

```hcl
# VPC Configuration - REQUIRED
vpc_id             = "vpc-xxxxx"                # Your VPC ID
private_subnet_ids = ["subnet-xxxxx", "subnet-yyyyy"]  # Your private subnets

# S3 Configuration
export_bucket_name   = "eftsure-mssql-exports"  # Your S3 bucket
export_prefix        = "exports/"               # Root prefix
data_source_name     = "admin_portal"           # Team/source name
create_export_bucket = false                    # Set true if bucket doesn't exist

# Alerts
alert_email = "data-engineering@eftsure.com"    # Your email

# Database Configuration
us_database_name    = "ProductionDB"             # Your US database name
au_database_name    = "ProductionDB"             # Your AU database name

# Table Selection (empty = all tables)
us_tables_to_export = ""  # or "dbo.Orders,dbo.Customers"
au_tables_to_export = ""  # or "dbo.Orders,dbo.Customers"
```

**About data_source_name**: This creates a folder in S3 to organize exports by team or application:
- `admin_portal` - for admin portal database exports
- `customer_api` - for customer API database exports  
- `finance_system` - for finance system exports

Output path: `s3://bucket/exports/data_source/region/database/timestamp/tables.csv.gz`

### 1.4 Configure Sensitive Credentials (load-env.ps1)
**CRITICAL**: This file contains sensitive data - never commit it!

Edit `load-env.ps1`:

```powershell
# US Database Credentials
$env:TF_VAR_us_mssql_host     = "us-db.internal.eftsure.com"    # CHANGE
$env:TF_VAR_us_mssql_user     = "db_export_user"                # CHANGE
$env:TF_VAR_us_mssql_password = "ACTUAL_PASSWORD_HERE"          # CHANGE

# AU Database Credentials
$env:TF_VAR_au_mssql_host     = "au-db.internal.eftsure.com"    # CHANGE
$env:TF_VAR_au_mssql_user     = "db_export_user"                # CHANGE
$env:TF_VAR_au_mssql_password = "ACTUAL_PASSWORD_HERE"          # CHANGE
```

Load the environment:
```powershell
.\load-env.ps1
```

Verify:
```powershell
echo $env:TF_VAR_us_mssql_host
echo $env:TF_VAR_au_mssql_host
```

## Step 2: Verify Network Connectivity

Before deploying, verify your local machine or bastion host can reach the MSSQL instances:

### 2.1 Test from Bastion/VPN
```bash
# Test US database
telnet us-db.internal.eftsure.com 1433

# Test AU database  
telnet au-db.internal.eftsure.com 1433
```

If telnet works, you have network connectivity. If not:
- Check VPN connection
- Verify security groups
- Check network ACLs
- Verify route tables

## Step 3: Initialize Terraform

```bash
terraform init
```

Expected output:
```
Initializing the backend...
Successfully configured the backend "s3"!
Initializing provider plugins...
Terraform has been successfully initialized!
```

## Step 4: Plan Deployment

Review what will be created:

```bash
terraform plan
```

Review the output carefully. You should see:
- ECR repository
- ECS cluster and task definitions (US and AU)
- Secrets Manager secrets
- S3 bucket configuration (if creating)
- Step Functions state machine
- IAM roles and policies
- CloudWatch log groups and alarms
- SNS topics

Expected resource count: ~40-50 resources

## Step 5: Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted. Deployment takes ~2-3 minutes.

**Note the outputs**, especially:
- `ecr_repository_url`
- `step_function_arn`
- `manual_execution_command`

## Step 6: Build and Push Docker Image

### 6.1 Navigate to Docker Directory
```bash
cd docker
```

### 6.2 Build and Push
```bash
./build-and-push.sh
```

This will:
1. Build the Docker image with MSSQL tools
2. Tag it with your ECR repository
3. Push to ECR

Expected time: ~3-5 minutes (depending on internet speed)

### 6.3 Verify Image in ECR
```bash
aws ecr describe-images \
  --repository-name mssql-bcp-export-bcp \
  --region ap-southeast-2
```

## Step 7: Update ECS Task Definitions

After pushing the Docker image, update the ECS task definitions:

```bash
cd ..
terraform apply
```

This ensures ECS uses the latest Docker image.

## Step 8: Test Execution

### 8.1 Manual Test via AWS Console

1. Go to Step Functions console
2. Find your state machine: `mssql-bcp-export`
3. Click "Start execution"
4. Use default input: `{}`
5. Click "Start execution"

### 8.2 Manual Test via CLI

Use the command from Terraform outputs:

```bash
aws stepfunctions start-execution \
  --state-machine-arn <YOUR_ARN> \
  --name test-$(date +%Y%m%d-%H%M%S)
```

### 8.3 Monitor Execution

**Step Functions Console:**
- Watch the execution graph
- Check for green (success) or red (failure) states

**CloudWatch Logs:**
```bash
# US export logs
aws logs tail /aws/ecs/mssql-bcp-export-us --follow

# AU export logs
aws logs tail /aws/ecs/mssql-bcp-export-au --follow

# Step Functions logs
aws logs tail /aws/vendedlogs/states/mssql-bcp-export --follow
```

## Step 9: Verify Output in S3

Check that files were created:

```bash
aws s3 ls s3://YOUR-BUCKET/exports/admin_portal/ --recursive
```

Expected structure:
```
exports/admin_portal/us/ProductionDB/export-20260204-120000/dbo_Orders.csv.gz
exports/admin_portal/us/ProductionDB/export-20260204-120000/dbo_Customers.csv.gz
exports/admin_portal/au/ProductionDB/export-20260204-120000/dbo_Orders.csv.gz
exports/admin_portal/au/ProductionDB/export-20260204-120000/dbo_Customers.csv.gz
```

Download a file to verify:
```bash
aws s3 cp s3://YOUR-BUCKET/exports/admin_portal/us/ProductionDB/export-20260204-120000/dbo_Orders.csv.gz .
gunzip dbo_Orders.csv.gz
head dbo_Orders.csv
```

## Step 10: Configure Email Alerts

### 10.1 Confirm SNS Subscriptions

After deployment, you'll receive two emails:
1. **Notifications topic** - for successful exports
2. **Alerts topic** - for failures

Click "Confirm subscription" in both emails.

### 10.2 Test Alert
Trigger a failure to test alerts:

```bash
# Temporarily disable both regions to trigger failure
terraform apply -var="enable_us_export=false" -var="enable_au_export=false"

# Try to execute (will fail)
aws stepfunctions start-execution \
  --state-machine-arn <YOUR_ARN> \
  --name test-failure-$(date +%Y%m%d-%H%M%S)

# Re-enable regions
terraform apply
```

You should receive an alert email.

## Step 11: Enable Scheduled Execution

Scheduled execution is enabled by default (2 AM UTC daily).

To modify schedule:
```hcl
# In terraform.tfvars
schedule_expression = "cron(0 6 * * ? *)"  # 6 AM UTC
```

To disable schedule:
```hcl
# In terraform.tfvars
enable_schedule = false
```

Apply changes:
```bash
terraform apply
```

## Step 12: Access CloudWatch Dashboard

1. Get dashboard URL from Terraform outputs:
   ```bash
   terraform output dashboard_url
   ```

2. Open URL in browser

3. Review metrics:
   - Execution success/failure rates
   - Task duration
   - Rows exported
   - Recent errors

## Common Issues and Solutions

### Issue: "Cannot connect to MSSQL"

**Symptoms:**
- ECS task fails immediately
- Logs show "Cannot establish TCP connection"

**Solutions:**
1. Verify ECS tasks are in correct subnets with VPN routes
2. Check security group allows outbound port 1433
3. Test connectivity from bastion host
4. Verify MSSQL instance is accessible from VPC

### Issue: "Invalid credentials"

**Symptoms:**
- TCP connection succeeds
- SQLCMD authentication fails

**Solutions:**
1. Verify credentials in `load-env.ps1`
2. Check Secrets Manager values:
   ```bash
   aws secretsmanager get-secret-value --secret-id mssql-bcp-export/us/credentials
   ```
3. Test credentials from bastion:
   ```bash
   sqlcmd -S host,1433 -U user -P password -Q "SELECT 1"
   ```

### Issue: "Table not found"

**Symptoms:**
- Some tables export, others fail
- Logs show "Invalid object name"

**Solutions:**
1. Verify table names (case-sensitive in queries)
2. Check schema.table format: `dbo.Orders` not just `Orders`
3. Verify user has SELECT permissions on all tables
4. If exporting all tables, check that `is_ms_shipped = 0` filter is correct

### Issue: "S3 upload fails"

**Symptoms:**
- BCP export succeeds
- S3 upload fails with permission error

**Solutions:**
1. Verify IAM task role has S3 PutObject permissions
2. Check bucket policy doesn't deny writes
3. Verify bucket name matches terraform.tfvars

### Issue: "Task timeout"

**Symptoms:**
- Task runs for max time then times out
- Large tables not fully exported

**Solutions:**
1. Increase timeout:
   ```hcl
   task_timeout_seconds = 14400  # 4 hours
   ```
2. Increase Fargate resources:
   ```hcl
   fargate_cpu    = 4096   # 4 vCPUs
   fargate_memory = 16384  # 16 GB
   ```
3. Split large tables across multiple exports
4. Use table filtering to export incrementally

## Performance Tuning

### Optimize for Large Exports

```hcl
# In terraform.tfvars
fargate_cpu               = 4096   # 4 vCPUs
fargate_memory            = 16384  # 16 GB
fargate_ephemeral_storage = 200    # GB

us_bcp_batch_size = 50000  # Larger batches
au_bcp_batch_size = 50000

task_timeout_seconds = 14400  # 4 hours
```

### Optimize for Cost

```hcl
# Use smaller resources for small databases
fargate_cpu               = 1024   # 1 vCPU
fargate_memory            = 4096   # 4 GB
fargate_ephemeral_storage = 50     # GB

# Use Fargate Spot (modify ECS task definitions)
# 50-70% cheaper but may be interrupted
```

### Optimize for Speed

```hcl
# Use parallel execution
execution_mode = "parallel"

# Increase resources
fargate_cpu    = 8192   # 8 vCPUs
fargate_memory = 32768  # 32 GB
```

## Monitoring and Maintenance

### Daily Checks
- Review CloudWatch dashboard
- Check SNS email alerts
- Verify S3 objects created

### Weekly Tasks
- Review CloudWatch alarms
- Check ECS task logs for warnings
- Verify export file sizes are consistent

### Monthly Tasks
- Review and optimize Fargate resource allocation
- Clean up old S3 exports (automated via lifecycle policy)
- Rotate database credentials in Secrets Manager
- Review and update table filters if needed

## Cleanup (Destroy Resources)

To completely remove all resources:

```bash
# WARNING: This deletes everything!
terraform destroy
```

To keep S3 data but remove infrastructure:

```hcl
# In terraform.tfvars
create_export_bucket = false
```

Then:
```bash
terraform destroy
```

S3 bucket will be preserved.

## Next Steps

1. **Integrate with Snowflake**: Use Snowpipe to auto-ingest exported files
2. **Add monitoring**: Set up custom CloudWatch dashboards
3. **Optimize costs**: Review Fargate resource usage after first week
4. **Implement CDC**: Consider change data capture for incremental exports
5. **Add data quality checks**: Validate exported data before uploading to S3

## Support

For issues or questions:
- Check CloudWatch Logs first
- Review this deployment guide
- Contact: data-engineering@eftsure.com
