# S3 Folder Structure Guide

## Overview

The export pipeline uses a hierarchical S3 folder structure to organize exports by data source, region, database, and timestamp.

## Folder Hierarchy

```
s3://bucket-name/
└── exports/                          # Root prefix (configurable)
    └── {data_source}/                # Team or application name
        └── {region}/                 # us or au
            └── {database}/           # Database name
                └── {timestamp}/      # export-YYYYMMDD-HHMMSS
                    ├── table1.csv.gz
                    ├── table2.csv.gz
                    └── table3.csv.gz
```

## Configuration Variables

| Variable | Example | Description |
|----------|---------|-------------|
| `export_bucket_name` | `eftsure-mssql-exports` | S3 bucket name |
| `export_prefix` | `exports/` | Root prefix for all exports |
| `data_source_name` | `admin_portal` | Team/application folder |
| `REGION` | `us` or `au` | Set automatically per task |
| `DATABASE_NAME` | `ProductionDB` | Database being exported |
| `JOB_ID` | `export-20260204-120000` | Timestamp-based unique ID |

## Example Path

**Configuration:**
```hcl
export_bucket_name = "eftsure-mssql-exports"
export_prefix      = "exports/"
data_source_name   = "admin_portal"
us_database_name   = "ProductionDB"
```

**Resulting S3 Path:**
```
s3://eftsure-mssql-exports/exports/admin_portal/us/ProductionDB/export-20260204-120000/dbo_Orders.csv.gz
```

**Breakdown:**
- `eftsure-mssql-exports` - Bucket (from `export_bucket_name`)
- `exports/` - Root prefix (from `export_prefix`)
- `admin_portal/` - Data source (from `data_source_name`)
- `us/` - Region (automatically set)
- `ProductionDB/` - Database (from `us_database_name`)
- `export-20260204-120000/` - Job timestamp (auto-generated)
- `dbo_Orders.csv.gz` - Table export file

## Multi-Team Usage

You can run multiple instances of this pipeline for different teams by changing the `data_source_name`:

### Admin Portal Team
```hcl
data_source_name = "admin_portal"
us_database_name = "AdminPortalDB"
au_database_name = "AdminPortalDB"
```
Output: `s3://bucket/exports/admin_portal/us/AdminPortalDB/timestamp/`

### Customer API Team
```hcl
data_source_name = "customer_api"
us_database_name = "CustomerDB"
au_database_name = "CustomerDB"
```
Output: `s3://bucket/exports/customer_api/us/CustomerDB/timestamp/`

### Finance Team
```hcl
data_source_name = "finance_system"
us_database_name = "FinanceDB"
au_database_name = "FinanceDB"
```
Output: `s3://bucket/exports/finance_system/us/FinanceDB/timestamp/`

## Benefits of This Structure

### 1. Clear Organization
- Easy to identify which team owns which data
- Clear separation between regions
- Obvious which database the data came from

### 2. Multi-Database Support
Each region can have different database names:
```hcl
us_database_name = "ProductionDB_US"
au_database_name = "ProductionDB_AU"
```
Output:
- `exports/admin_portal/us/ProductionDB_US/timestamp/`
- `exports/admin_portal/au/ProductionDB_AU/timestamp/`

### 3. Historical Tracking
Timestamps are preserved in the path, making it easy to:
- Compare exports over time
- Find exports from specific dates
- Debug data issues by date

### 4. S3 Lifecycle Policies
Apply different retention policies per data source:
```hcl
# Keep admin_portal exports for 90 days
exports/admin_portal/* → expire after 90 days

# Keep finance_system exports for 7 years
exports/finance_system/* → transition to Glacier after 30 days
```

### 5. IAM Permissions
Grant team-specific access:
```json
{
  "Effect": "Allow",
  "Action": ["s3:GetObject", "s3:ListBucket"],
  "Resource": [
    "arn:aws:s3:::bucket/exports/admin_portal/*"
  ]
}
```

## Listing Exports

### All exports for a data source
```bash
aws s3 ls s3://bucket/exports/admin_portal/ --recursive
```

### All exports for a region
```bash
aws s3 ls s3://bucket/exports/admin_portal/us/ --recursive
```

### All exports for a database
```bash
aws s3 ls s3://bucket/exports/admin_portal/us/ProductionDB/ --recursive
```

### Specific export run
```bash
aws s3 ls s3://bucket/exports/admin_portal/us/ProductionDB/export-20260204-120000/
```

## Snowflake Integration

When creating Snowpipe or COPY commands, use the full path pattern:

```sql
-- Stage for admin portal US data
CREATE STAGE admin_portal_us_stage
  URL = 's3://bucket/exports/admin_portal/us/ProductionDB/'
  CREDENTIALS = (AWS_KEY_ID = '...' AWS_SECRET_KEY = '...');

-- Snowpipe that auto-ingests new exports
CREATE PIPE admin_portal_orders_pipe
  AUTO_INGEST = TRUE
  AS
  COPY INTO orders_raw
  FROM @admin_portal_us_stage
  PATTERN = '.*/dbo_Orders.csv.gz';
```

## Finding Latest Export

### Using AWS CLI
```bash
# Get latest timestamp folder for US
aws s3 ls s3://bucket/exports/admin_portal/us/ProductionDB/ \
  | sort | tail -1

# Download latest export
LATEST=$(aws s3 ls s3://bucket/exports/admin_portal/us/ProductionDB/ \
  | sort | tail -1 | awk '{print $2}')
aws s3 cp s3://bucket/exports/admin_portal/us/ProductionDB/$LATEST . --recursive
```

### Using Python
```python
import boto3
from datetime import datetime

s3 = boto3.client('s3')

# List all timestamp folders
prefix = 'exports/admin_portal/us/ProductionDB/'
response = s3.list_objects_v2(
    Bucket='bucket',
    Prefix=prefix,
    Delimiter='/'
)

# Get latest
timestamps = [p['Prefix'] for p in response.get('CommonPrefixes', [])]
latest = max(timestamps)

print(f"Latest export: {latest}")
```

## Customization

### Change Root Prefix
```hcl
export_prefix = "data-exports/"  # instead of "exports/"
```
Output: `s3://bucket/data-exports/admin_portal/us/ProductionDB/timestamp/`

### Remove Prefix Entirely
```hcl
export_prefix = ""
```
Output: `s3://bucket/admin_portal/us/ProductionDB/timestamp/`

### Use Date-Based Folders
Modify `entrypoint.sh` to use date instead of timestamp:
```bash
# Change from:
JOB_ID="export-$(date +%Y%m%d-%H%M%S)"

# To:
JOB_ID="$(date +%Y-%m-%d)"
```
Output: `s3://bucket/exports/admin_portal/us/ProductionDB/2026-02-04/`

## Summary

The hierarchical structure provides:
- **Organization** by team, region, and database
- **Flexibility** for multiple teams to share infrastructure
- **Clarity** in data ownership and location
- **Scalability** for growing data needs
- **Integration** ease with downstream systems like Snowflake

Configure `data_source_name` to match your team or application, and the pipeline handles the rest automatically.
