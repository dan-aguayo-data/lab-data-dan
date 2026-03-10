# Service Account Management Guide

## 📋 Overview

This guide explains how to add, configure, and manage Snowflake service accounts (automated system users) using Terraform.

---

## 🏗️ Service Account Architecture

### What is a Service Account?

A **service account** is a non-human user used by applications and services to connect to Snowflake:
- ✅ dbt (data transformation)
- ✅ Fivetran (data ingestion)
- ✅ Power BI (analytics and reporting)
- ✅ Python scripts, APIs, etc.

### Global vs Environment-Specific

#### Global Components (Deployed Once)
**Location:** `snowflake/global/`

- ✅ **Service Account Users** - `SVC_DBT`, `SVC_FIVETRAN`, `SVC_POWERBI`
- ✅ **Service Account Roles** - `SVC_ROLE_DBT_RW`, `SVC_ROLE_FIVETRAN_RW`, `SVC_ROLE_POWERBI_RO`
- ✅ **Warehouses** - Compute resources for queries

**Why Global?**
- Users and roles are shared across all environments
- Single authentication mechanism (RSA key pair or password)
- Simplified user management

#### Environment-Specific Components
**Location:** `snowflake/environments/{dev|uat|prod}/`

- ✅ **Database Grants** - Permission to access `STAGING_DEV`, `STAGING_UAT`, etc.
- ✅ **Schema Grants** - Permission to read/write specific schemas
- ✅ **Future Object Grants** - Automatic permissions on new tables/views

**Why Environment-Specific?**
- Isolate permissions per environment
- DEV can have full access, PROD restricted
- Prevent accidental cross-environment data access

---

## ➕ Adding a New Service Account

### Complete Process (8 Steps)

#### Step 1: Define User in Global

**File:** `snowflake/global/service_accounts.tf`

```hcl
# Add new user
resource "snowflake_user" "svc_airflow" {
  name         = "SVC_AIRFLOW"
  comment      = "Service account for Airflow orchestration"
  login_name   = "SVC_AIRFLOW"
  display_name = "Airflow Service Account"
  
  # RSA public key authentication (recommended)
  rsa_public_key = var.airflow_rsa_public_key
  
  # OR password authentication (not recommended)
  # password = var.airflow_password
  
  default_warehouse = "EFT_DATA_ETL"
  default_role      = "SVC_ROLE_AIRFLOW_RW"
  
  must_change_password = false
}
```

#### Step 2: Define Role in Global

```hcl
# Add new role
resource "snowflake_account_role" "svc_airflow_rw" {
  name    = "SVC_ROLE_AIRFLOW_RW"
  comment = "Read-write role for Airflow service account"
}
```

#### Step 3: Grant Role to User in Global

```hcl
# Grant role to user
resource "snowflake_grant_account_role" "airflow_rw_to_user" {
  role_name = snowflake_account_role.svc_airflow_rw.name
  user_name = snowflake_user.svc_airflow.name
}
```

#### Step 4: Grant Role to SYSADMIN (Global)

```hcl
# Grant role to SYSADMIN for management
resource "snowflake_grant_account_role" "airflow_rw_to_sysadmin" {
  role_name        = snowflake_account_role.svc_airflow_rw.name
  parent_role_name = "SYSADMIN"
}
```

#### Step 5: Add Variables (Global)

**File:** `snowflake/global/variables.tf`

```hcl
variable "airflow_rsa_public_key" {
  description = "RSA public key for Airflow service account"
  type        = string
  sensitive   = true
}

variable "airflow_role_name" {
  description = "Role name for Airflow service account"
  type        = string
  default     = "SVC_ROLE_AIRFLOW_RW"
}
```

#### Step 6: Add to Module Variables (Environment)

**File:** `modules/snowflake_environment/variables.tf`

```hcl
variable "airflow_role_name" {
  description = "Role name for Airflow service account grants"
  type        = string
}
```

#### Step 7: Pass Variable to Module (Environment)

**File:** `environments/dev/main.tf` (and uat, prod)

```hcl
module "environment" {
  source = "../../modules/snowflake_environment"
  
  # ... existing variables ...
  
  # Add new service account role
  airflow_role_name = var.airflow_role_name
}
```

**File:** `environments/dev/variables.tf`

```hcl
variable "airflow_role_name" {
  description = "Role name for Airflow service account"
  type        = string
  default     = "SVC_ROLE_AIRFLOW_RW"
}
```

#### Step 8: Add Grants (Environment Module)

**File:** `modules/snowflake_environment/grants_service_accounts.tf`

```hcl
# Database grants
resource "snowflake_grant_privileges_to_account_role" "airflow_databases" {
  for_each = local.all_databases
  
  account_role_name = var.airflow_role_name
  privileges        = ["USAGE", "MONITOR"]
  
  on_account_object {
    object_type = "DATABASE"
    object_name = each.value.name
  }
}

# Schema grants (read-write on non-LANDING)
resource "snowflake_grant_privileges_to_account_role" "airflow_non_landing_schema" {
  for_each = {
    for item in local.non_landing_schemas_list :
    "${item.database}.${item.schema}" => item
  }
  
  account_role_name = var.airflow_role_name
  privileges        = ["USAGE", "MONITOR", "CREATE TABLE", "CREATE VIEW"]
  
  on_schema {
    schema_name = "\"${each.value.database}\".\"${each.value.schema}\""
  }
  
  depends_on = [snowflake_schema.schemas]
}

# Future tables grant
resource "snowflake_grant_privileges_to_account_role" "airflow_non_landing_future_tables" {
  for_each = {
    for item in local.non_landing_schemas_list :
    "${item.database}.${item.schema}" => item
  }
  
  account_role_name = var.airflow_role_name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]
  
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }
  
  depends_on = [snowflake_schema.schemas]
}

# Future views grant
resource "snowflake_grant_privileges_to_account_role" "airflow_non_landing_future_views" {
  for_each = {
    for item in local.non_landing_schemas_list :
    "${item.database}.${item.schema}" => item
  }
  
  account_role_name = var.airflow_role_name
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }
  
  depends_on = [snowflake_schema.schemas]
}
```

---

## 🔐 Authentication Methods

### Method 1: RSA Key Pair (Recommended)

**Why?**
- ✅ More secure than passwords
- ✅ No password expiration
- ✅ Industry best practice
- ✅ Required for some integrations (dbt Cloud)

**Setup:**

```powershell
# Generate private key
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out snowflake_key.p8 -nocrypt

# Generate public key
openssl rsa -in snowflake_key.p8 -pubout -out snowflake_key.pub

# Remove header/footer from public key
# Copy key content (without BEGIN/END lines)
```

**Store Keys:**
- **Private Key** → AWS Secrets Manager (`/snowflake/service_accounts/airflow/private_key`)
- **Public Key** → Terraform variable or AWS Secrets Manager

**Terraform Config:**
```hcl
resource "snowflake_user" "svc_airflow" {
  name           = "SVC_AIRFLOW"
  rsa_public_key = var.airflow_rsa_public_key  # Public key only
  # ...
}
```

**Application Config:**
```python
# Python/dbt example
connection_params = {
    "user": "SVC_AIRFLOW",
    "account": "your_account",
    "private_key": private_key_bytes,  # Load from Secrets Manager
    "role": "SVC_ROLE_AIRFLOW_RW"
}
```

---

### Method 2: Password (Not Recommended)

**Drawbacks:**
- ❌ Less secure
- ❌ Password expiration
- ❌ Not supported by some tools

**Only use if:**
- Tool doesn't support key pair auth
- Temporary/testing purposes

**Terraform Config:**
```hcl
resource "snowflake_user" "svc_example" {
  name                 = "SVC_EXAMPLE"
  password             = var.example_password  # Store in Secrets Manager
  must_change_password = false
  # ...
}
```

---

## 📋 Common Service Account Patterns

### Pattern 1: Read-Only Analytics (Power BI, Tableau)

```hcl
# User
resource "snowflake_user" "svc_powerbi" {
  name              = "SVC_POWERBI"
  rsa_public_key    = var.powerbi_rsa_public_key
  default_warehouse = "EFT_DATA_ANALYTICS"
  default_role      = "SVC_ROLE_POWERBI_RO"
}

# Role
resource "snowflake_account_role" "svc_powerbi_ro" {
  name    = "SVC_ROLE_POWERBI_RO"
  comment = "Read-only role for Power BI"
}

# Grants (in environment module)
# - Database: USAGE
# - Schema: USAGE
# - Tables/Views: SELECT only
```

---

### Pattern 2: Data Ingestion (Fivetran, Airbyte)

```hcl
# User
resource "snowflake_user" "svc_fivetran" {
  name              = "SVC_FIVETRAN"
  rsa_public_key    = var.fivetran_rsa_public_key
  default_warehouse = "EFT_DATA_INGESTION"
  default_role      = "SVC_ROLE_FIVETRAN_RW"
}

# Role
resource "snowflake_account_role" "svc_fivetran_rw" {
  name    = "SVC_ROLE_FIVETRAN_RW"
  comment = "Read-write role for Fivetran ingestion"
}

# Grants (in environment module)
# - LANDING databases only
# - Schema: USAGE, MONITOR, CREATE TABLE, CREATE STAGE
# - Tables: INSERT, UPDATE, DELETE, TRUNCATE, SELECT
```

---

### Pattern 3: Data Transformation (dbt)

```hcl
# User
resource "snowflake_user" "svc_dbt" {
  name              = "SVC_DBT"
  rsa_public_key    = var.dbt_rsa_public_key
  default_warehouse = "EFT_DATA_TRANSFORMATION"
  default_role      = "SVC_ROLE_DBT_RW"
}

# Role
resource "snowflake_account_role" "svc_dbt_rw" {
  name    = "SVC_ROLE_DBT_RW"
  comment = "Read-write role for dbt transformations"
}

# Grants (in environment module)
# - All databases except LANDING
# - Schema: USAGE, MONITOR, CREATE TABLE, CREATE VIEW, CREATE STAGE
# - Tables/Views: Full permissions (SELECT, INSERT, UPDATE, DELETE, TRUNCATE)
```

---

## 🧪 Testing Service Account Access

### Step 1: Deploy Global Resources

```powershell
cd snowflake/global
terraform plan
terraform apply
```

### Step 2: Deploy Environment Grants

```powershell
cd ../environments/dev
terraform plan
terraform apply
```

### Step 3: Test in Snowflake UI

```sql
-- Switch to service account role
USE ROLE SVC_ROLE_AIRFLOW_RW;

-- Check available databases
SHOW DATABASES;

-- Test schema access
USE SCHEMA "STAGING_DEV"."FP_DATA";

-- Test table creation (if read-write)
CREATE TABLE test_table (id INT, name STRING);

-- Test query
SELECT * FROM test_table;

-- Cleanup
DROP TABLE test_table;
```

### Step 4: Test from Application

```python
# Python example
import snowflake.connector

conn = snowflake.connector.connect(
    user='SVC_AIRFLOW',
    account='your_account',
    private_key=private_key_bytes,
    role='SVC_ROLE_AIRFLOW_RW',
    warehouse='EFT_DATA_ETL',
    database='STAGING_DEV',
    schema='FP_DATA'
)

# Test query
cursor = conn.cursor()
cursor.execute("SELECT CURRENT_ROLE(), CURRENT_DATABASE(), CURRENT_SCHEMA()")
print(cursor.fetchone())
```

---

## 🐛 Troubleshooting

### "User does not exist"

**Cause:** User not created in global

**Solution:**
```powershell
cd snowflake/global
terraform plan  # Check if user is in plan
terraform apply
```

---

### "Role does not exist"

**Cause:** Role not created in global

**Solution:**
```powershell
cd snowflake/global
terraform plan  # Check if role is in plan
terraform apply
```

---

### Authentication Failure

**Cause:** Incorrect private key or password

**Solutions:**

**For RSA Key Pair:**
```powershell
# Verify public key in Snowflake
DESC USER SVC_AIRFLOW;
# Check RSA_PUBLIC_KEY field

# Ensure private key format is correct (PKCS#8)
openssl pkcs8 -topk8 -inform PEM -in old_key.pem -out new_key.p8 -nocrypt
```

**For Password:**
```sql
-- Reset password in Snowflake
ALTER USER SVC_AIRFLOW SET PASSWORD = 'new_secure_password';
```

---

### Permission Denied After Grants

**Cause:** Role not granted to user or SYSADMIN

**Solution:**
```sql
-- Grant role to user
GRANT ROLE SVC_ROLE_AIRFLOW_RW TO USER SVC_AIRFLOW;

-- Grant role to SYSADMIN
GRANT ROLE SVC_ROLE_AIRFLOW_RW TO ROLE SYSADMIN;
```

---

### Connection Timeout

**Cause:** Network policy or firewall blocking connection

**Solution:**
```sql
-- Check network policies
SHOW NETWORK POLICIES;

-- Check user's network policy
DESC USER SVC_AIRFLOW;

-- If needed, update network policy to allow IP
```

---

## 🔄 Key Rotation

### When to Rotate Keys
- ✅ Every 90 days (recommended)
- ✅ When key may be compromised
- ✅ When employee leaves (if they had access)

### Rotation Process

#### Step 1: Generate New Key Pair

```powershell
# Generate new private key
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out snowflake_key_new.p8 -nocrypt

# Generate new public key
openssl rsa -in snowflake_key_new.p8 -pubout -out snowflake_key_new.pub
```

#### Step 2: Add Second Public Key (Zero Downtime)

```sql
-- Snowflake supports 2 public keys simultaneously
ALTER USER SVC_AIRFLOW SET RSA_PUBLIC_KEY_2 = 'MIIBIjANBgkq...';
```

#### Step 3: Update Application

Update application to use new private key

#### Step 4: Remove Old Key

```sql
-- After confirming new key works
ALTER USER SVC_AIRFLOW UNSET RSA_PUBLIC_KEY;

-- Promote key 2 to key 1
ALTER USER SVC_AIRFLOW SET RSA_PUBLIC_KEY = 'MIIBIjANBgkq...';
ALTER USER SVC_AIRFLOW UNSET RSA_PUBLIC_KEY_2;
```

---

## 📋 Checklist: Adding Service Account

**Global (One Time):**
- [ ] Add user resource in `global/service_accounts.tf`
- [ ] Add role resource in `global/service_accounts.tf`
- [ ] Grant role to user
- [ ] Grant role to SYSADMIN
- [ ] Add variables in `global/variables.tf`
- [ ] Deploy global: `terraform apply`
- [ ] Generate RSA key pair (if using)
- [ ] Store private key in Secrets Manager

**Environment (Per Environment):**
- [ ] Add variable to `modules/snowflake_environment/variables.tf`
- [ ] Pass variable in `environments/{env}/main.tf`
- [ ] Add variable to `environments/{env}/variables.tf`
- [ ] Add grants in `modules/snowflake_environment/grants_service_accounts.tf`
- [ ] Test in DEV: `terraform apply`
- [ ] Verify grants in Snowflake
- [ ] Test connection from application
- [ ] Promote to UAT
- [ ] Promote to PROD

**Testing:**
- [ ] Test authentication
- [ ] Test database access
- [ ] Test schema access
- [ ] Test table create (if read-write)
- [ ] Test query execution
- [ ] Document connection details
- [ ] Share credentials securely with team

---

## 🔗 Related Documentation

- [Grant Management](README_GRANTS.md)
- [Database Management](README_DATABASES.md)
- [Project Overview](README_PROJECT.md)

---

## 📚 Additional Resources

- [Snowflake Key Pair Authentication](https://docs.snowflake.com/en/user-guide/key-pair-auth)
- [Service Account Best Practices](https://docs.snowflake.com/en/user-guide/admin-user-management)
- [Network Policies](https://docs.snowflake.com/en/user-guide/network-policies)
