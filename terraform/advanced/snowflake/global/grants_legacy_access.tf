# ============================================================
# SF_LEGACY_ACCESS - Read-only access to legacy databases
# ============================================================
# This role exists outside Terraform and provides read-only access to legacy databases
# and the analytics warehouse

locals {
  legacy_access_databases = ["FIVETRAN", "CUSTOMER_SUCCESS", "CUSTOMER_SUPPORT", "REVENUE_OPERATIONS"]
}

# ============================================================
# LEGACY DATABASES - Read-only
# ============================================================

resource "snowflake_grant_privileges_to_account_role" "legacy_access_database_usage" {
  for_each = toset(local.legacy_access_databases)
  
  account_role_name = "SF_LEGACY_ACCESS"
  privileges        = ["USAGE", "MONITOR"]
  
  on_account_object {
    object_type = "DATABASE"
    object_name = each.value
  }
}

resource "snowflake_grant_privileges_to_account_role" "legacy_access_all_schemas" {
  for_each = toset(local.legacy_access_databases)
  
  account_role_name = "SF_LEGACY_ACCESS"
  privileges        = ["USAGE"]
  
  on_schema {
    all_schemas_in_database = each.value
  }
}

resource "snowflake_grant_privileges_to_account_role" "legacy_access_future_schemas" {
  for_each = toset(local.legacy_access_databases)
  
  account_role_name = "SF_LEGACY_ACCESS"
  privileges        = ["USAGE"]
  
  on_schema {
    future_schemas_in_database = each.value
  }
}

resource "snowflake_grant_privileges_to_account_role" "legacy_access_all_tables" {
  for_each = toset(local.legacy_access_databases)
  
  account_role_name = "SF_LEGACY_ACCESS"
  privileges        = ["SELECT"]
  
  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_database        = each.value
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "legacy_access_future_tables" {
  for_each = toset(local.legacy_access_databases)
  
  account_role_name = "SF_LEGACY_ACCESS"
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_database        = each.value
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "legacy_access_all_views" {
  for_each = toset(local.legacy_access_databases)
  
  account_role_name = "SF_LEGACY_ACCESS"
  privileges        = ["SELECT"]
  
  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_database        = each.value
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "legacy_access_future_views" {
  for_each = toset(local.legacy_access_databases)
  
  account_role_name = "SF_LEGACY_ACCESS"
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_database        = each.value
    }
  }
}

# ============================================================
# HUBSPOTEFTSURE - IMPORTED PRIVILEGES
# ============================================================

resource "snowflake_grant_privileges_to_account_role" "legacy_access_hubspot_imported" {
  account_role_name = "SF_LEGACY_ACCESS"
  privileges        = ["IMPORTED PRIVILEGES"]
  
  on_account_object {
    object_type = "DATABASE"
    object_name = "HUBSPOTEFTSURE"
  }
}

# ============================================================
# ANALYTICS WAREHOUSE
# ============================================================

resource "snowflake_grant_privileges_to_account_role" "legacy_access_warehouse" {
  account_role_name = "SF_LEGACY_ACCESS"
  privileges        = ["USAGE"]
  
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.analytics.name
  }
}


# ============================================================
# COMPUTE_WH WAREHOUSE
# ============================================================

resource "snowflake_grant_privileges_to_account_role" "legacy_access_compute_wh" {
  account_role_name = "SF_LEGACY_ACCESS"
  privileges        = ["USAGE"]
  
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = "COMPUTE_WH"
  }
}


# ============================================================
# REVENUE_OPERATIONS - Additional Write Permissions
# ============================================================
# SF_LEGACY_ACCESS gets elevated permissions on this database only

# Create schemas
resource "snowflake_grant_privileges_to_account_role" "legacy_access_revops_create_schema" {
  account_role_name = "SF_LEGACY_ACCESS"
  privileges        = ["CREATE SCHEMA"]
  
  on_account_object {
    object_type = "DATABASE"
    object_name = "REVENUE_OPERATIONS"
  }
}

# Write to all existing tables
resource "snowflake_grant_privileges_to_account_role" "legacy_access_revops_write_tables" {
  account_role_name = "SF_LEGACY_ACCESS"
  privileges        = ["INSERT", "UPDATE", "DELETE", "TRUNCATE"]
  
  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_database        = "REVENUE_OPERATIONS"
    }
  }
}

# Write to future tables
resource "snowflake_grant_privileges_to_account_role" "legacy_access_revops_write_future_tables" {
  account_role_name = "SF_LEGACY_ACCESS"
  privileges        = ["INSERT", "UPDATE", "DELETE", "TRUNCATE"]
  
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_database        = "REVENUE_OPERATIONS"
    }
  }
}

# Create tables in all existing schemas
resource "snowflake_grant_privileges_to_account_role" "legacy_access_revops_create_tables" {
  account_role_name = "SF_LEGACY_ACCESS"
  privileges        = ["CREATE TABLE", "CREATE VIEW"]
  
  on_schema {
    all_schemas_in_database = "REVENUE_OPERATIONS"
  }
}

# Create tables in future schemas
resource "snowflake_grant_privileges_to_account_role" "legacy_access_revops_create_future" {
  account_role_name = "SF_LEGACY_ACCESS"
  privileges        = ["CREATE TABLE", "CREATE VIEW"]
  
  on_schema {
    future_schemas_in_database = "REVENUE_OPERATIONS"
  }
}

