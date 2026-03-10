# Database Management Guide

## 📋 Overview

This guide explains how to add, modify, and manage Snowflake databases and schemas using Terraform.

---

## 🏗️ Database Architecture

### Database Types

1. **STAGING** - Raw and lightly transformed data
2. **DWH_MART** - Business logic and analytics models
3. **LANDING** - Raw data ingestion from external sources
   - LANDING_FP (First Party)
   - LANDING_TP (Third Party)
   - LANDING_FILES (File-based ingestion)

### Naming Convention

```
{DATABASE_NAME}_{ENVIRONMENT}

Examples:
- STAGING_DEV
- DWH_MART_UAT
- LANDING_FP_PROD
```

---

## 📁 File Structure

**Configuration File:** `modules/snowflake_environment/databases.tf`

**Variables File:** `environments/{env}/terraform.tfvars`

---

## ➕ Adding a New Database

### Step 1: Define in tfvars

**File:** `environments/dev/terraform.tfvars` (or uat/prod)

```hcl
databases = {
  STAGING = {
    comment           = "Staging database for raw and lightly transformed data"
    data_retention_days = 1
    schemas           = ["FP_DATA", "TP_DATA", "HUBSPOT"]
  }
  
  DWH_MART = {
    comment           = "Data warehouse mart with business logic"
    data_retention_days = 1
    schemas           = ["FINANCE", "SALES", "OPERATIONS"]
  }
  
  # NEW DATABASE
  CUSTOMER_360 = {
    comment           = "Customer 360 unified view"
    data_retention_days = 1  # DEV: 1 day, PROD: 7 days
    schemas           = ["PROFILES", "INTERACTIONS", "PREFERENCES"]
  }
}
```

### Step 2: Plan the Change

```powershell
cd snowflake/environments/dev
terraform plan
```

**Expected Output:**
```
# module.environment.snowflake_database.databases["CUSTOMER_360"] will be created
+ resource "snowflake_database" "databases" {
    + name                 = "CUSTOMER_360_DEV"
    + comment              = "Customer 360 unified view"
    + data_retention_days  = 1
    ...
  }

# module.environment.snowflake_schema.schemas["CUSTOMER_360.PROFILES"] will be created
# module.environment.snowflake_schema.schemas["CUSTOMER_360.INTERACTIONS"] will be created
# module.environment.snowflake_schema.schemas["CUSTOMER_360.PREFERENCES"] will be created
```

### Step 3: Apply

```powershell
terraform apply
```

### Step 4: Verify in Snowflake

```sql
-- Show database
SHOW DATABASES LIKE 'CUSTOMER_360_DEV';

-- Show schemas
SHOW SCHEMAS IN DATABASE "CUSTOMER_360_DEV";

-- Verify comment
DESC DATABASE "CUSTOMER_360_DEV";
```

---

## ➕ Adding Schema to Existing Database

### Step 1: Update tfvars

**Before:**
```hcl
STAGING = {
  comment           = "Staging database"
  data_retention_days = 1
  schemas           = ["FP_DATA", "TP_DATA"]
}
```

**After:**
```hcl
STAGING = {
  comment           = "Staging database"
  data_retention_days = 1
  schemas           = ["FP_DATA", "TP_DATA", "SALESFORCE"]  # Added SALESFORCE
}
```

### Step 2: Plan and Apply

```powershell
terraform plan
terraform apply
```

**Result:** New schema `SALESFORCE` created with automatic grants!

---

## ➖ Removing a Schema

### ⚠️ WARNING: Data Loss

**Removing a schema deletes ALL tables, views, and data inside it!**

### Step 1: Backup Data (if needed)

```sql
-- Clone schema before removing
CREATE SCHEMA "STAGING_DEV"."OLD_SCHEMA_BACKUP" 
  CLONE "STAGING_DEV"."OLD_SCHEMA";
```

### Step 2: Remove from tfvars

**Before:**
```hcl
schemas = ["FP_DATA", "TP_DATA", "OLD_SCHEMA"]
```

**After:**
```hcl
schemas = ["FP_DATA", "TP_DATA"]  # Removed OLD_SCHEMA
```

### Step 3: Plan and Apply

```powershell
terraform plan  # Review what will be deleted
terraform apply
```

---

## 🔄 Database Lifecycle Protection

### DEV and UAT
```hcl
lifecycle {
  prevent_destroy = false  # Can be deleted
}
```

### PROD
```hcl
lifecycle {
  prevent_destroy = var.environment == "prod" ? true : false  # Protected!
}
```

**Result:** Cannot accidentally delete PROD databases with `terraform destroy`

**Override (Emergency Only):**
```powershell
terraform destroy -target=module.environment.snowflake_database.databases[\"STAGING\"]
# This will still fail in PROD due to lifecycle protection
```

---

## ⚙️ Database Configuration Options

### Data Retention

**Purpose:** How long Snowflake keeps historical data for Time Travel

```hcl
data_retention_days = 1   # DEV: Low cost
data_retention_days = 7   # UAT/PROD: Compliance
data_retention_days = 90  # PROD (Enterprise Edition): Extended retention
```

**Cost Impact:**
- Higher retention = higher storage costs
- DEV should use 1 day to minimize costs

### Comments

```hcl
comment = "Staging database for raw and lightly transformed data"
```

**Best Practice:**
- Describe purpose of database
- Mention data sources
- Note any special handling

---

## 📋 Common Database Patterns

### Pattern 1: LANDING Databases

**Purpose:** Raw data ingestion from external sources

```hcl
LANDING_FP = {
  comment           = "First-party raw data ingestion"
  data_retention_days = 1
  schemas           = [
    "EFTSURE_DEV",
    "LOOKUP",
    "STRIPE",
    "RECURLY"
  ]
}

LANDING_TP = {
  comment           = "Third-party raw data ingestion"
  data_retention_days = 1
  schemas           = [
    "HUBSPOT",
    "SEGMENT", 
    "GOOGLE_ADS"
  ]
}
```

**Characteristics:**
- Read-only for most users
- Write access for ETL tools (Fivetran)
- No transformations (raw data only)

---

### Pattern 2: STAGING Databases

**Purpose:** Lightly transformed data, intermediate processing

```hcl
STAGING = {
  comment           = "Staging area for data transformation"
  data_retention_days = 1
  schemas           = [
    "FP_DATA",
    "TP_DATA",
    "INTERMEDIATE"
  ]
}
```

**Characteristics:**
- Read-write for transformation tools (dbt)
- Intermediate transformations
- Not for end-user consumption

---

### Pattern 3: DWH_MART Databases

**Purpose:** Final analytics-ready data models

```hcl
DWH_MART = {
  comment           = "Data warehouse mart for analytics and reporting"
  data_retention_days = 7  # Higher retention for production analytics
  schemas           = [
    "FINANCE",
    "SALES",
    "OPERATIONS",
    "CUSTOMER"
  ]
}
```

**Characteristics:**
- Read-only for analysts
- Read-write for dbt (transformations)
- Business logic applied
- End-user facing

---

## 🧪 Testing Database Changes

### Step 1: Test in DEV First

```powershell
cd snowflake/environments/dev
terraform plan
terraform apply
```

### Step 2: Verify Structure

```sql
-- Show all databases in environment
SHOW DATABASES LIKE '%_DEV';

-- Show schemas in new database
SHOW SCHEMAS IN DATABASE "MY_NEW_DATABASE_DEV";

-- Verify data retention
DESC DATABASE "MY_NEW_DATABASE_DEV";
```

### Step 3: Test Permissions

```sql
-- Test service account access
USE ROLE SVC_ROLE_DBT_RW;
USE DATABASE "MY_NEW_DATABASE_DEV";
USE SCHEMA "MY_NEW_SCHEMA";
CREATE TABLE test (id INT);  -- Should work

-- Test analyst access
USE ROLE SF_DATA_ANALYST_DEV_RO;
USE DATABASE "MY_NEW_DATABASE_DEV";
USE SCHEMA "MY_NEW_SCHEMA";
SELECT * FROM test;  -- Should work
```

### Step 4: Promote to UAT/PROD

After DEV validation:

```powershell
# UAT
cd ../uat
# Copy tfvars changes from DEV
terraform plan
terraform apply

# PROD (requires approval)
cd ../prod
# Copy tfvars changes from UAT
terraform plan
# Submit for approval via GitHub Actions
```

---

## 🐛 Troubleshooting

### "Schema already exists"

**Cause:** Schema exists in Snowflake but not in Terraform state

**Solution 1: Import Existing Schema**
```powershell
terraform import 'module.environment.snowflake_schema.schemas["DATABASE_KEY.SCHEMA_NAME"]' '"DATABASE_NAME"."SCHEMA_NAME"'

# Example:
terraform import 'module.environment.snowflake_schema.schemas["STAGING.NEW_SCHEMA"]' '"STAGING_DEV"."NEW_SCHEMA"'
```

**Solution 2: Remove and Recreate**
```sql
-- In Snowflake (if safe to delete)
DROP SCHEMA "STAGING_DEV"."NEW_SCHEMA";
```

Then run `terraform apply`

---

### "Cannot drop database"

**Cause:** Database has dependent objects or lifecycle protection

**Solution:**
```powershell
# Check if PROD (protected by prevent_destroy)
# You cannot drop PROD databases via Terraform

# For DEV/UAT:
# 1. Remove all schemas first
# 2. Then remove database from tfvars
# 3. Apply changes
```

---

### Grants Failing After Adding Database

**Cause:** Grants trying to execute before database/schemas created

**Solution:**
```powershell
# Just run apply again
terraform apply
```

**Prevention:** Ensure `depends_on = [snowflake_schema.schemas]` in grant resources

---

### Database Name Collision

**Cause:** Database name already exists (wrong environment suffix)

**Example:**
```
Error: Database "STAGING" already exists
```

**Solution:** Database names are auto-suffixed with environment:
```hcl
# You define:
STAGING = { ... }

# Terraform creates:
STAGING_DEV    # in DEV
STAGING_UAT    # in UAT  
STAGING_PROD   # in PROD
```

**No action needed** - this is expected behavior!

---

## 📋 Checklist: Adding New Database

- [ ] Define database in `terraform.tfvars`
- [ ] Add all required schemas
- [ ] Set appropriate data retention
- [ ] Add descriptive comment
- [ ] Test with `terraform plan` in DEV
- [ ] Apply to DEV
- [ ] Verify in Snowflake
- [ ] Test grants (service accounts, analysts)
- [ ] Document any special handling
- [ ] Promote to UAT
- [ ] Promote to PROD (via approval workflow)

---

## 📋 Checklist: Adding New Schema

- [ ] Update database's `schemas` list in tfvars
- [ ] Test with `terraform plan`
- [ ] Apply changes
- [ ] Verify schema created
- [ ] Confirm grants applied automatically
- [ ] Test access with roles
- [ ] Document schema purpose

---

## 🔗 Related Documentation

- [Grant Management](README_GRANTS.md)
- [Service Account Management](README_SERVICE_ACCOUNT.md)
- [Project Overview](README_PROJECT.md)

---

## 📚 Additional Resources

### Snowflake Data Retention
- [Time Travel Documentation](https://docs.snowflake.com/en/user-guide/data-time-travel)
- Standard Edition: 0-1 days
- Enterprise Edition: 0-90 days

### Database Best Practices
- Use descriptive names
- Separate raw (LANDING) from transformed (STAGING, MART)
- Minimize retention in non-PROD environments
- Always protect PROD with lifecycle rules
- Document data sources and purpose
