# Grant Management Guide

## 📋 Overview

This guide explains how to add, modify, and manage permissions (grants) in Snowflake using Terraform.

---

## 🏗️ Grant Architecture

### Grant Types

1. **Service Account Grants** - Automated system access (dbt, Fivetran, Power BI)
2. **Analyst Grants** - Human user access (read-only, read-write)
3. **Administrative Grants** - All roles to SYSADMIN for management

### Grant Locations

```
modules/snowflake_environment/
├── grants_service_accounts.tf      # dbt, Fivetran, Power BI grants
├── grants_analyst_roles.tf         # Analyst role grants
└── grants_all_to_sysadmin.tf       # Role hierarchy
```

---

## 🔧 Adding Service Account Grants

### Example: Grant dbt Access to New Schema

**File:** `modules/snowflake_environment/grants_service_accounts.tf`

**Step 1: Add Schema Grant**

```hcl
# Find the existing dbt_non_landing_schema resource
resource "snowflake_grant_privileges_to_account_role" "dbt_non_landing_schema" {
  for_each = {
    for item in local.non_landing_schemas :
    "${item.database}.${item.schema}" => item
  }
  
  account_role_name = var.dbt_role_name
  privileges        = ["USAGE", "MONITOR", "CREATE TABLE", "CREATE VIEW", "CREATE STAGE", "CREATE FILE FORMAT"]
  
  on_schema {
    schema_name = "\"${each.value.database}\".\"${each.value.schema}\""
  }
  
  depends_on = [snowflake_schema.schemas]  # CRITICAL: Always include this!
}
```

**Step 2: Add Future Tables Grant**

```hcl
# Future tables grant (already exists, just verify it's there)
resource "snowflake_grant_privileges_to_account_role" "dbt_non_landing_future_tables" {
  for_each = {
    for item in local.non_landing_schemas :
    "${item.database}.${item.schema}" => item
  }
  
  account_role_name = var.dbt_role_name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE", "REFERENCES"]
  
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }
  
  depends_on = [snowflake_schema.schemas]  # CRITICAL!
}
```

**Result:** When you add a new schema to your `terraform.tfvars`, dbt automatically gets access!

---

## 👥 Adding Analyst Grants

### Example: Grant Analysts Access to New Schema

**File:** `modules/snowflake_environment/grants_analyst_roles.tf`

**The grants automatically cover new schemas!**

When you add a schema to `terraform.tfvars`, analyst grants are automatically applied based on:

- **analyst_ro** → Non-LANDING schemas (read-only)
- **analyst_sec_ro** → ALL schemas including LANDING (read-only)
- **analyst_rw** → Non-LANDING schemas (read-write, DEV only)

**No code changes needed!** Just add the schema to your tfvars.

---

## 🎯 Common Grant Patterns

### Pattern 1: Read-Only Access

```hcl
resource "snowflake_grant_privileges_to_account_role" "example_ro" {
  for_each = local.schemas_map
  
  account_role_name = "MY_ROLE_RO"
  privileges        = ["USAGE"]  # Schema-level
  
  on_schema {
    schema_name = "\"${each.value.database}\".\"${each.value.schema}\""
  }
  
  depends_on = [snowflake_schema.schemas]
}

# Future tables - read-only
resource "snowflake_grant_privileges_to_account_role" "example_ro_tables" {
  for_each = local.schemas_map
  
  account_role_name = "MY_ROLE_RO"
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }
  
  depends_on = [snowflake_schema.schemas]
}
```

---

### Pattern 2: Read-Write Access

```hcl
resource "snowflake_grant_privileges_to_account_role" "example_rw" {
  for_each = local.schemas_map
  
  account_role_name = "MY_ROLE_RW"
  privileges        = ["USAGE", "MONITOR", "CREATE TABLE", "CREATE VIEW"]
  
  on_schema {
    schema_name = "\"${each.value.database}\".\"${each.value.schema}\""
  }
  
  depends_on = [snowflake_schema.schemas]
}

# Future tables - read-write
resource "snowflake_grant_privileges_to_account_role" "example_rw_tables" {
  for_each = local.schemas_map
  
  account_role_name = "MY_ROLE_RW"
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]
  
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }
  
  depends_on = [snowflake_schema.schemas]
}
```

---

### Pattern 3: Database-Level Access

```hcl
resource "snowflake_grant_privileges_to_account_role" "example_db" {
  for_each = local.all_databases
  
  account_role_name = "MY_ROLE"
  privileges        = ["USAGE", "MONITOR"]
  
  on_account_object {
    object_type = "DATABASE"
    object_name = each.value.name
  }
}
```

---

## 🔍 Filtering Schemas

### Exclude LANDING Databases

```hcl
for_each = {
  for item in local.all_schemas_list :
  "${item.database}.${item.schema}" => item
  if !startswith(item.database_key, "LANDING_")  # Excludes LANDING_*
}
```

### Include Only Specific Database

```hcl
for_each = {
  for item in local.all_schemas_list :
  "${item.database}.${item.schema}" => item
  if startswith(item.database_key, "DWH_MART")  # Only DWH_MART
}
```

### Environment-Specific Grants (DEV Only)

```hcl
for_each = var.environment == "dev" ? local.schemas_map : {}
```

---

## ⚠️ Critical Rules

### 1. Always Include depends_on

**✅ CORRECT:**
```hcl
resource "snowflake_grant_privileges_to_account_role" "my_grant" {
  # ... grant config ...
  
  depends_on = [snowflake_schema.schemas]  # CRITICAL!
}
```

**❌ INCORRECT:**
```hcl
resource "snowflake_grant_privileges_to_account_role" "my_grant" {
  # ... grant config ...
  
  # Missing depends_on = error!
}
```

**Why?** Without `depends_on`, Terraform may try to grant permissions before schemas exist!

---

### 2. Use Correct Schema Reference Format

**✅ CORRECT:**
```hcl
schema_name = "\"${each.value.database}\".\"${each.value.schema}\""
# Result: "STAGING_DEV"."FP_DATA"
```

**❌ INCORRECT:**
```hcl
schema_name = "${each.value.database}.${each.value.schema}"
# Result: STAGING_DEV.FP_DATA (missing quotes - will fail!)
```

---

### 3. Grant to Both Current and Future Objects

**Always grant permissions to:**
- ✅ Schema itself (USAGE, MONITOR)
- ✅ Future tables (SELECT, INSERT, etc.)
- ✅ Future views (SELECT)

**Example:**
```hcl
# 1. Schema grant
resource "snowflake_grant_privileges_to_account_role" "schema" {
  privileges = ["USAGE", "MONITOR"]
  on_schema { ... }
}

# 2. Future tables grant
resource "snowflake_grant_privileges_to_account_role" "future_tables" {
  privileges = ["SELECT"]
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema = "..."
    }
  }
}

# 3. Future views grant
resource "snowflake_grant_privileges_to_account_role" "future_views" {
  privileges = ["SELECT"]
  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema = "..."
    }
  }
}
```

---

## 🧪 Testing Grants

### Step 1: Plan

```powershell
cd snowflake/environments/dev
terraform plan
```

**Look for:**
```
# module.environment.snowflake_grant_privileges_to_account_role.my_new_grant will be created
```

### Step 2: Apply to DEV

```powershell
terraform apply
```

### Step 3: Verify in Snowflake

```sql
-- Show grants to a role
SHOW GRANTS TO ROLE SVC_ROLE_DBT_RW;

-- Show grants on a schema
SHOW GRANTS ON SCHEMA "STAGING_DEV"."FP_DATA";

-- Show future grants
SHOW FUTURE GRANTS IN SCHEMA "STAGING_DEV"."FP_DATA";
```

### Step 4: Test Access

```sql
-- Switch to the role
USE ROLE SVC_ROLE_DBT_RW;

-- Try to access the schema
USE SCHEMA "STAGING_DEV"."FP_DATA";

-- Try to create a table (if read-write)
CREATE TABLE test_table (id INT);
```

---

## 🐛 Troubleshooting

### "Object does not exist or not authorized"

**Cause:** Schema doesn't exist yet

**Solution:**
```powershell
# Run apply again - Terraform will create schemas first
terraform apply
```

---

### Grants Taking Too Long

**Cause:** Snowflake API slowness

**Solution:**
- Wait 2-3 minutes
- If timeout occurs, run `terraform apply` again
- Terraform will pick up where it left off

---

### Permission Denied After Grant

**Cause:** Need to grant role to user or to SYSADMIN

**Solution:**
```sql
-- Grant role to user
GRANT ROLE MY_NEW_ROLE TO USER my_user;

-- OR ensure role is granted to SYSADMIN (check grants_all_to_sysadmin.tf)
```

---

## 📋 Checklist: Adding New Grant

- [ ] Identify which file to edit (`grants_service_accounts.tf` or `grants_analyst_roles.tf`)
- [ ] Add schema-level grant
- [ ] Add future tables grant
- [ ] Add future views grant (if needed)
- [ ] Include `depends_on = [snowflake_schema.schemas]`
- [ ] Test with `terraform plan` in DEV
- [ ] Apply to DEV
- [ ] Verify in Snowflake
- [ ] Test access with role
- [ ] Promote to UAT/PROD

---

## 🔗 Related Documentation

- [Database Management](README_DATABASES.md)
- [Service Account Management](README_SERVICE_ACCOUNT.md)
- [Project Overview](README_PROJECT.md)
