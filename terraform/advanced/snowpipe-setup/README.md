# Snowpipe Terraform - Production

Auto-ingest S3 CSV exports into Snowflake using Snowpipe.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ECS Fargate   │───▶│    S3 Bucket    │───▶│  Snowflake SQS  │
│  (BCP exports)  │    │   exports/*     │    │  (auto-managed) │
└─────────────────┘    └─────────────────┘    └────────┬────────┘
                                                       │
                                                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │  Landing Table  │◀───│    Snowpipe     │
                       │  RAW_EXPORTS    │    │  (auto-ingest)  │
                       └─────────────────┘    └─────────────────┘
```

## Configuration Parameters

### Snowflake Target (update in terraform.tfvars)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `snowflake_database` | Target database | - |
| `snowflake_schema` | Target schema | - |
| `snowflake_warehouse` | Warehouse for operations | - |

### Object Names

| Parameter | Description | Default |
|-----------|-------------|---------|
| `landing_table_name` | Name of raw landing table | `RAW_EXPORTS` |
| `pipe_name` | Name of Snowpipe | `PIPE_S3_EXPORTS` |
| `stage_name` | Name of external stage | `STG_S3_EXPORTS` |
| `file_format_name` | Name of file format | `FF_CSV_PIPE_GZIP` |
| `storage_integration_name` | Storage integration name | Auto-generated |

### Table Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `max_columns` | Number of COL_1 to COL_N columns | `50` |

### File Format

| Parameter | Description | Default |
|-----------|-------------|---------|
| `field_delimiter` | CSV field delimiter | `\|` |
| `skip_header` | Header rows to skip | `0` |
| `null_if` | Strings treated as NULL | `["", "NULL", "null", "\\N"]` |

### S3 Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `s3_bucket_name` | S3 bucket name | - |
| `s3_prefix` | Prefix for exports | `exports/` |

## Prerequisites

1. **Snowflake database and schema must exist:**
   ```sql
   CREATE DATABASE IF NOT EXISTS LANDING;
   CREATE SCHEMA IF NOT EXISTS LANDING.SNOWPIPE;
   ```

2. **Terraform service account permissions:**
   ```sql
   GRANT CREATE INTEGRATION ON ACCOUNT TO ROLE SVC_ROLE_TERRAFORM_RW;
   GRANT USAGE ON DATABASE LANDING TO ROLE SVC_ROLE_TERRAFORM_RW;
   GRANT ALL ON SCHEMA LANDING.SNOWPIPE TO ROLE SVC_ROLE_TERRAFORM_RW;
   ```

3. **S3 bucket must exist**

## Deployment

### 1. Set Environment Variables

```powershell
$env:TF_VAR_snowflake_organization = "BXNRJRX"
$env:TF_VAR_snowflake_account_name = "XQ57619"
$env:TF_VAR_snowflake_account = "su73143.ap-southeast-2"
$env:TF_VAR_snowflake_user = "SVC_DATA_TERRAFORM"
$env:TF_VAR_snowflake_role = "SVC_ROLE_TERRAFORM_RW"
```

### 2. Update terraform.tfvars

Edit the file and update:
- `snowflake_database` - Target database
- `snowflake_schema` - Target schema
- `snowflake_warehouse` - Warehouse name
- `s3_bucket_name` - Your S3 bucket
- `max_columns` - Adjust if needed

### 3. Initialize and Apply

```powershell
terraform init
terraform plan
terraform apply
```

## Verification

```sql
-- Check pipe is running
SELECT SYSTEM$PIPE_STATUS('LANDING.SNOWPIPE.PIPE_S3_EXPORTS');

-- List files in stage
LIST @LANDING.SNOWPIPE.STG_S3_EXPORTS;

-- View loaded data
SELECT * FROM LANDING.SNOWPIPE.RAW_EXPORTS LIMIT 10;

-- Force refresh (load existing files)
ALTER PIPE LANDING.SNOWPIPE.PIPE_S3_EXPORTS REFRESH;
```

## Landing Table Schema

```sql
RAW_EXPORTS
├── _LOADED_AT         TIMESTAMP_NTZ  -- Load timestamp
├── _FILENAME          VARCHAR        -- Full S3 path
├── _FILE_ROW_NUMBER   NUMBER         -- Row number in file
├── _JOB_ID            VARCHAR        -- From path: exports/{JOB_ID}/...
├── _SOURCE_TABLE      VARCHAR        -- From filename: dbo_Table.csv.gz
├── COL_1              VARCHAR
├── COL_2              VARCHAR
├── ...
└── COL_50             VARCHAR
```

## File Requirements

| Requirement | Value |
|-------------|-------|
| Path format | `exports/{job-id}/{table}.csv.gz` |
| Extension | `.csv.gz` |
| Delimiter | Pipe `\|` |
| Header | None |
| Encoding | UTF-8 |

## Adding More Pipes

See [ADDING_PIPES.md](ADDING_PIPES.md) for instructions on creating additional Snowpipes.

## Destroy and Recreate

If you need a clean slate:

```powershell
# Destroy all resources
terraform destroy

# Recreate
terraform apply
```

**Note:** This will delete the landing table and all data in it.

## File Structure

```
snowpipe-terraform/
├── main.tf                  # Providers, backend, locals
├── variables.tf             # All configurable parameters
├── terraform.tfvars         # Your configuration values
├── aws_iam.tf               # IAM policy and role
├── aws_s3_notifications.tf  # S3 event notifications
├── snowflake.tf             # Snowflake resources
├── outputs.tf               # Output values
├── ADDING_PIPES.md          # Guide for adding pipes
└── README.md                # This file
```

## Troubleshooting

### Pipe not loading files

1. Check file ends in `.csv.gz`
2. Check path is `exports/{id}/file.csv.gz`
3. Run `ALTER PIPE ... REFRESH`
4. Check `SYSTEM$PIPE_STATUS`

### Permission errors

```sql
-- Verify storage integration
DESC STORAGE INTEGRATION MSSQL_EXPORTS_PROD_S3_INT;

-- Test stage access
LIST @LANDING.SNOWPIPE.STG_S3_EXPORTS;
```

### Parse errors

```sql
-- Check copy history
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.COPY_HISTORY
WHERE TABLE_NAME = 'RAW_EXPORTS'
ORDER BY LAST_LOAD_TIME DESC
LIMIT 10;
```
