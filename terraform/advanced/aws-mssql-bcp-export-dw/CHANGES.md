# Changes Summary - Hierarchical S3 Structure

## What Changed

✅ **ZIP file format** instead of tar.gz  
✅ **Hierarchical S3 folder structure** with team/region/database organization

## New S3 Structure

### Before (Original)
```
s3://bucket/exports/
├── us/export-20260204-120000/tables.csv.gz
└── au/export-20260204-120000/tables.csv.gz
```

### After (Updated)
```
s3://bucket/exports/
└── admin_portal/              # ← NEW: Data source/team name
    ├── us/                    
    │   └── ProductionDB/      # ← NEW: Database name
    │       └── export-20260204-120000/
    │           └── tables.csv.gz
    └── au/
        └── ProductionDB/      # ← NEW: Database name
            └── export-20260204-120000/
                └── tables.csv.gz
```

## New Configuration Variable

Add to `terraform.tfvars`:

```hcl
data_source_name = "admin_portal"  # Team or application name
```

Examples:
- `"admin_portal"` → `s3://bucket/exports/admin_portal/us/ProductionDB/timestamp/`
- `"customer_api"` → `s3://bucket/exports/customer_api/us/CustomerDB/timestamp/`
- `"finance_system"` → `s3://bucket/exports/finance_system/us/FinanceDB/timestamp/`

## Full Path Example

**Configuration:**
```hcl
export_bucket_name = "eftsure-mssql-exports"
export_prefix      = "exports/"
data_source_name   = "admin_portal"
us_database_name   = "ProductionDB"
au_database_name   = "ProductionDB"
```

**Resulting Paths:**
```
s3://eftsure-mssql-exports/exports/admin_portal/us/ProductionDB/export-20260204-120000/dbo_Orders.csv.gz
s3://eftsure-mssql-exports/exports/admin_portal/au/ProductionDB/export-20260204-120000/dbo_Orders.csv.gz
```

## Benefits

1. **Multi-team support** - Different teams can use the same bucket
2. **Clear organization** - Easy to see team → region → database → timestamp
3. **Database flexibility** - US and AU can have different database names
4. **IAM policies** - Grant access per team: `exports/admin_portal/*`
5. **Lifecycle rules** - Different retention per team
6. **Snowflake integration** - Clear stage paths per team

## Files Updated

✅ `global_variables.tf` - Added `data_source_name` variable  
✅ `terraform.tfvars` - Added example configuration  
✅ `aws_ecs_us.tf` - Updated environment variables  
✅ `aws_ecs_au.tf` - Updated environment variables  
✅ `docker/scripts/entrypoint.sh` - Updated S3 path construction  
✅ `README.md` - Updated S3 structure documentation  
✅ `DEPLOYMENT.md` - Updated deployment guide  
✅ `QUICKREF.md` - Updated quick reference  
✅ `S3_STRUCTURE.md` - NEW comprehensive S3 guide

## Usage

1. **Extract the ZIP file**
2. **Edit `terraform.tfvars`** and set:
   ```hcl
   data_source_name = "your_team_name"
   ```
3. **Deploy normally** - the new structure will be used automatically

## Example Scenarios

### Scenario 1: Single Team
```hcl
data_source_name = "admin_portal"
us_database_name = "ProductionDB"
au_database_name = "ProductionDB"
```
Output: `exports/admin_portal/{us|au}/ProductionDB/timestamp/`

### Scenario 2: Multiple Teams (Deploy separate Terraform instances)

**Team A (Admin Portal):**
```hcl
project_name     = "mssql-bcp-export-admin"
data_source_name = "admin_portal"
us_database_name = "AdminDB"
```

**Team B (Customer API):**
```hcl
project_name     = "mssql-bcp-export-api"
data_source_name = "customer_api"
us_database_name = "CustomerDB"
```

Both can export to the same S3 bucket with clear separation!

### Scenario 3: Different Databases per Region
```hcl
data_source_name = "finance"
us_database_name = "FinanceDB_US"
au_database_name = "FinanceDB_AU"
```
Output:
- `exports/finance/us/FinanceDB_US/timestamp/`
- `exports/finance/au/FinanceDB_AU/timestamp/`

## Backward Compatibility

⚠️ This is a **breaking change** if you have existing exports.

**Migration Options:**

1. **Fresh start** - Use new structure going forward
2. **Parallel run** - Keep old pipeline running, deploy new one alongside
3. **Manual migration** - Use AWS CLI to reorganize existing files

## Questions?

See `S3_STRUCTURE.md` for comprehensive documentation on the new folder structure.
