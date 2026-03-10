# Snowpipe BCP - Multi-Bucket S3 Ingestion

Auto-ingest CSV exports from multiple S3 buckets into Snowflake using Snowpipe.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  S3 Bucket 1    │───▶│  Stage 1        │───▶│                 │
│  (mssql_exports)│    │  Pipe 1         │    │                 │
└─────────────────┘    └─────────────────┘    │                 │
                                              │   RAW_EXPORTS   │
┌─────────────────┐    ┌─────────────────┐    │     Table       │
│  S3 Bucket 2    │───▶│  Stage 2        │───▶│                 │
│  (europe_data)  │    │  Pipe 2         │    │ _SOURCE_BUCKET  │
└─────────────────┘    └─────────────────┘    │  identifies     │
        ...                  ...              │  the source     │
                                              └─────────────────┘
```

**Shared Resources:**
- 1 Storage Integration (covers all buckets)
- 1 IAM Role (access to all buckets)
- 1 File Format
- 1 Landing Table (all data lands here with `_SOURCE_BUCKET` column)
- 1 Cleanup Task

**Per-Bucket Resources:**
- 1 Stage per bucket
- 1 Pipe per bucket
- 1 S3 Notification per bucket

## Prerequisites

### 1. Create DynamoDB Table for State Locking

```bash
aws dynamodb create-table \
  --table-name terraform-state-lock-data-bcp-snowpipe \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-southeast-2
```

### 2. Ensure S3 Backend Bucket Exists

The state bucket `eft-data-terraform-backend` must exist.

### 3. Create Snowflake Database and Schema

```sql
CREATE DATABASE IF NOT EXISTS LANDING_DEV;
CREATE SCHEMA IF NOT EXISTS LANDING_DEV.SNOWPIPE;

-- Grant permissions to terraform role
GRANT USAGE ON DATABASE LANDING_DEV TO ROLE SVC_ROLE_TERRAFORM_RW;
GRANT ALL ON SCHEMA LANDING_DEV.SNOWPIPE TO ROLE SVC_ROLE_TERRAFORM_RW;
GRANT EXECUTE TASK ON ACCOUNT TO ROLE SVC_ROLE_TERRAFORM_RW;
```

### 4. Ensure S3 Bucket Exists

The bucket `eftsure-mssql-exports-dw` must exist before running Terraform.

## Deployment Steps

```powershell
# 1. Load environment variables
. .\load-env.ps1

# 2. Initialize Terraform
terraform init

# 3. Review the plan
terraform plan

# 4. Apply (may need to run twice due to IAM propagation)
terraform apply

# 5. If IAM error occurs, wait 30 seconds and apply again
terraform apply
```

## Verify Deployment

```sql
-- Check all pipes are running
SELECT SYSTEM$PIPE_STATUS('LANDING_DEV.SNOWPIPE.PIPE_MSSQL_EXPORTS');

-- List files in stage
LIST @LANDING_DEV.SNOWPIPE.STG_MSSQL_EXPORTS;

-- View loaded data
SELECT _LOADED_AT, _SOURCE_BUCKET, _JOB_ID, _SOURCE_TABLE, 
       COL_1, COL_2, COL_3
FROM LANDING_DEV.SNOWPIPE.RAW_EXPORTS
ORDER BY _LOADED_AT DESC
LIMIT 10;

-- Check cleanup task
SHOW TASKS LIKE 'TASK_CLEANUP%' IN SCHEMA LANDING_DEV.SNOWPIPE;

-- Manual refresh if needed
ALTER PIPE LANDING_DEV.SNOWPIPE.PIPE_MSSQL_EXPORTS REFRESH;
```

## Adding a New Bucket

1. **Edit `terraform.tfvars`:**

```hcl
s3_buckets = {
  mssql_exports = {
    name   = "eftsure-mssql-exports-dw"
    prefix = "exports/"
    region = "ap-southeast-2"
  }
  # Add new bucket:
  europe_exports = {
    name   = "eftsure-europe-exports"
    prefix = "exports/"
    region = "eu-west-1"
  }
}
```

2. **Apply:**

```powershell
terraform apply
```

This will create:
- New stage: `STG_EUROPE_EXPORTS`
- New pipe: `PIPE_EUROPE_EXPORTS`
- New S3 notification on the bucket
- Updated IAM policy with access to new bucket
- Updated storage integration with new location

All data flows to the same `RAW_EXPORTS` table. Use `_SOURCE_BUCKET` to filter by source.

## Cross-Region Buckets

If a bucket is in a different region (e.g., `eu-west-1`):

1. **S3 notifications work cross-region** - Snowflake's SQS queue can receive events from any region
2. **IAM works globally** - No changes needed
3. **Storage integration works cross-region** - Snowflake can access S3 in any region

Just ensure the bucket exists before running `terraform apply`.

## File Requirements

| Requirement | Value |
|-------------|-------|
| Path format | `{prefix}{job-id}/{table}.csv.gz` |
| Extension | `.csv.gz` |
| Delimiter | Pipe `\|` |
| Header | None |
| Max columns | 150 |

## Landing Table Schema

```sql
RAW_EXPORTS
├── _LOADED_AT         TIMESTAMP_NTZ  -- Load timestamp
├── _FILENAME          VARCHAR        -- Full S3 path
├── _FILE_ROW_NUMBER   NUMBER         -- Row number in file
├── _JOB_ID            VARCHAR        -- From path
├── _SOURCE_TABLE      VARCHAR        -- From filename
├── _SOURCE_BUCKET     VARCHAR        -- Bucket identifier (key from s3_buckets)
├── COL_1              VARCHAR
├── COL_2              VARCHAR
├── ...
└── COL_150            VARCHAR
```

## Data Retention

- Data older than 7 days is automatically deleted
- Cleanup runs daily at 2 AM UTC
- Configurable via `cleanup_retention_days` and `cleanup_cron_schedule`

## Troubleshooting

### Pipe not loading files

```sql
-- Check pipe status
SELECT SYSTEM$PIPE_STATUS('LANDING_DEV.SNOWPIPE.PIPE_MSSQL_EXPORTS');

-- Force refresh
ALTER PIPE LANDING_DEV.SNOWPIPE.PIPE_MSSQL_EXPORTS REFRESH;
```

### Permission errors

```sql
-- Verify storage integration
DESC STORAGE INTEGRATION BCP_SNOWPIPE_PROD_S3_INT;

-- Test stage access
LIST @LANDING_DEV.SNOWPIPE.STG_MSSQL_EXPORTS;
```

### Check copy history

```sql
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.COPY_HISTORY
WHERE TABLE_NAME = 'RAW_EXPORTS'
ORDER BY LAST_LOAD_TIME DESC
LIMIT 10;
```

## File Structure

```
snowpipe-bcp/
├── main.tf                  # Providers, backend, locals
├── variables.tf             # All configurable parameters
├── terraform.tfvars         # Your configuration
├── load-env.ps1             # Environment variable loader
├── aws_iam.tf               # IAM policy and role
├── aws_s3_notifications.tf  # S3 event notifications
├── snowflake.tf             # Integration, format, table, stages, pipes
├── snowflake_cleanup.tf     # Cleanup procedure and task
├── outputs.tf               # Output values
└── README.md                # This file
```
