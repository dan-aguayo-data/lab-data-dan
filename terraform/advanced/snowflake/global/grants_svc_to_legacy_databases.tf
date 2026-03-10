# =================
# LEGACY DATABASE GRANTS - Service Accounts
# =================
# Grants to databases that exist outside this Terraform configuration

locals {
  legacy_databases = ["FIVETRAN", "CUSTOMER_SUCCESS", "CUSTOMER_SUPPORT", "REVENUE_OPERATIONS"]
}

# ============================================================
# DBT ROLE → FIVETRAN Database (Read-only)
# ============================================================

resource "snowflake_grant_privileges_to_account_role" "dbt_fivetran_db" {
  account_role_name = snowflake_account_role.dbt_rw.name
  privileges        = ["USAGE", "MONITOR"]
  
  on_account_object {
    object_type = "DATABASE"
    object_name = "FIVETRAN"
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_fivetran_all_schemas" {
  account_role_name = snowflake_account_role.dbt_rw.name
  privileges        = ["USAGE"]
  
  on_schema {
    all_schemas_in_database = "FIVETRAN"
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_fivetran_future_schemas" {
  account_role_name = snowflake_account_role.dbt_rw.name
  privileges        = ["USAGE"]
  
  on_schema {
    future_schemas_in_database = "FIVETRAN"
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_fivetran_all_tables" {
  account_role_name = snowflake_account_role.dbt_rw.name
  privileges        = ["SELECT"]
  
  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_database        = "FIVETRAN"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_fivetran_future_tables" {
  account_role_name = snowflake_account_role.dbt_rw.name
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_database        = "FIVETRAN"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_fivetran_all_views" {
  account_role_name = snowflake_account_role.dbt_rw.name
  privileges        = ["SELECT"]
  
  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_database        = "FIVETRAN"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_fivetran_future_views" {
  account_role_name = snowflake_account_role.dbt_rw.name
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_database        = "FIVETRAN"
    }
  }
}

# ============================================================
# FIVETRAN ROLE → FIVETRAN Database (Read-write)
# ============================================================

resource "snowflake_grant_privileges_to_account_role" "fivetran_fivetran_db" {
  account_role_name = snowflake_account_role.fivetran_rw.name
  privileges        = ["USAGE", "MONITOR", "CREATE SCHEMA"]
  
  on_account_object {
    object_type = "DATABASE"
    object_name = "FIVETRAN"
  }
}

resource "snowflake_grant_privileges_to_account_role" "fivetran_fivetran_all_schemas" {
  account_role_name = snowflake_account_role.fivetran_rw.name
  privileges        = ["USAGE", "MONITOR", "CREATE TABLE", "CREATE VIEW", "CREATE STAGE", "CREATE FILE FORMAT", "CREATE PIPE"]
  
  on_schema {
    all_schemas_in_database = "FIVETRAN"
  }
}

resource "snowflake_grant_privileges_to_account_role" "fivetran_fivetran_future_schemas" {
  account_role_name = snowflake_account_role.fivetran_rw.name
  privileges        = ["USAGE", "MONITOR", "CREATE TABLE", "CREATE VIEW", "CREATE STAGE", "CREATE FILE FORMAT", "CREATE PIPE"]
  
  on_schema {
    future_schemas_in_database = "FIVETRAN"
  }
}

resource "snowflake_grant_privileges_to_account_role" "fivetran_fivetran_all_tables" {
  account_role_name = snowflake_account_role.fivetran_rw.name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]
  
  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_database        = "FIVETRAN"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "fivetran_fivetran_future_tables" {
  account_role_name = snowflake_account_role.fivetran_rw.name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]
  
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_database        = "FIVETRAN"
    }
  }
}

# ============================================================
# POWER BI ROLE → FIVETRAN Database (Read-only)
# ============================================================

resource "snowflake_grant_privileges_to_account_role" "powerbi_fivetran_db" {
  account_role_name = snowflake_account_role.powerbi_ro.name
  privileges        = ["USAGE", "MONITOR"]
  
  on_account_object {
    object_type = "DATABASE"
    object_name = "FIVETRAN"
  }
}

resource "snowflake_grant_privileges_to_account_role" "powerbi_fivetran_all_schemas" {
  account_role_name = snowflake_account_role.powerbi_ro.name
  privileges        = ["USAGE"]
  
  on_schema {
    all_schemas_in_database = "FIVETRAN"
  }
}

resource "snowflake_grant_privileges_to_account_role" "powerbi_fivetran_future_schemas" {
  account_role_name = snowflake_account_role.powerbi_ro.name
  privileges        = ["USAGE"]
  
  on_schema {
    future_schemas_in_database = "FIVETRAN"
  }
}

resource "snowflake_grant_privileges_to_account_role" "powerbi_fivetran_all_tables" {
  account_role_name = snowflake_account_role.powerbi_ro.name
  privileges        = ["SELECT"]
  
  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_database        = "FIVETRAN"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "powerbi_fivetran_future_tables" {
  account_role_name = snowflake_account_role.powerbi_ro.name
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_database        = "FIVETRAN"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "powerbi_fivetran_all_views" {
  account_role_name = snowflake_account_role.powerbi_ro.name
  privileges        = ["SELECT"]
  
  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_database        = "FIVETRAN"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "powerbi_fivetran_future_views" {
  account_role_name = snowflake_account_role.powerbi_ro.name
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_database        = "FIVETRAN"
    }
  }
}

# ============================================================
# HUBSPOTEFTSURE Database - IMPORTED PRIVILEGES
# ============================================================

resource "snowflake_grant_privileges_to_account_role" "dbt_hubspot_imported" {
  account_role_name = snowflake_account_role.dbt_rw.name
  privileges        = ["IMPORTED PRIVILEGES"]
  
  on_account_object {
    object_type = "DATABASE"
    object_name = "HUBSPOTEFTSURE"
  }
}

resource "snowflake_grant_privileges_to_account_role" "powerbi_hubspot_imported" {
  account_role_name = snowflake_account_role.powerbi_ro.name
  privileges        = ["IMPORTED PRIVILEGES"]
  
  on_account_object {
    object_type = "DATABASE"
    object_name = "HUBSPOTEFTSURE"
  }
}

# ============================================================
# OTHER LEGACY DATABASES - PowerBI Read-only
# ============================================================

resource "snowflake_grant_privileges_to_account_role" "powerbi_legacy_db" {
  for_each = toset(local.legacy_databases)
  
  account_role_name = snowflake_account_role.powerbi_ro.name
  privileges        = ["USAGE", "MONITOR"]
  
  on_account_object {
    object_type = "DATABASE"
    object_name = each.value
  }
}

resource "snowflake_grant_privileges_to_account_role" "powerbi_legacy_all_schemas" {
  for_each = toset(local.legacy_databases)
  
  account_role_name = snowflake_account_role.powerbi_ro.name
  privileges        = ["USAGE"]
  
  on_schema {
    all_schemas_in_database = each.value
  }
}

resource "snowflake_grant_privileges_to_account_role" "powerbi_legacy_future_schemas" {
  for_each = toset(local.legacy_databases)
  
  account_role_name = snowflake_account_role.powerbi_ro.name
  privileges        = ["USAGE"]
  
  on_schema {
    future_schemas_in_database = each.value
  }
}

resource "snowflake_grant_privileges_to_account_role" "powerbi_legacy_all_tables" {
  for_each = toset(local.legacy_databases)
  
  account_role_name = snowflake_account_role.powerbi_ro.name
  privileges        = ["SELECT"]
  
  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_database        = each.value
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "powerbi_legacy_future_tables" {
  for_each = toset(local.legacy_databases)
  
  account_role_name = snowflake_account_role.powerbi_ro.name
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_database        = each.value
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "powerbi_legacy_all_views" {
  for_each = toset(local.legacy_databases)
  
  account_role_name = snowflake_account_role.powerbi_ro.name
  privileges        = ["SELECT"]
  
  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_database        = each.value
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "powerbi_legacy_future_views" {
  for_each = toset(local.legacy_databases)
  
  account_role_name = snowflake_account_role.powerbi_ro.name
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_database        = each.value
    }
  }
}


# ============================================================
# REVENUE_OPERATIONS.ADHOC_ANALYTICS - Schema-level future grants
# ============================================================
# Schema-level future grants exist on this schema (SYSADMIN, SF_LEGACY_ACCESS)
# which OVERRIDE database-level future grants. Any role needing access to
# future objects in this schema must have schema-level grants here.

resource "snowflake_grant_privileges_to_account_role" "powerbi_revops_adhoc_future_tables" {
  account_role_name = snowflake_account_role.powerbi_ro.name
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "REVENUE_OPERATIONS.ADHOC_ANALYTICS"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "powerbi_revops_adhoc_future_views" {
  account_role_name = snowflake_account_role.powerbi_ro.name
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema          = "REVENUE_OPERATIONS.ADHOC_ANALYTICS"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "legacy_access_revops_adhoc_future_tables" {
  account_role_name = "SF_LEGACY_ACCESS"
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "REVENUE_OPERATIONS.ADHOC_ANALYTICS"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "legacy_access_revops_adhoc_future_views" {
  account_role_name = "SF_LEGACY_ACCESS"
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema          = "REVENUE_OPERATIONS.ADHOC_ANALYTICS"
    }
  }
}


# ============================================================
# DBT ROLE → REVENUE_OPERATIONS Database (Read-only)
# ============================================================

resource "snowflake_grant_privileges_to_account_role" "dbt_revenue_operations_db" {
  account_role_name = snowflake_account_role.dbt_rw.name
  privileges        = ["USAGE", "MONITOR"]
  
  on_account_object {
    object_type = "DATABASE"
    object_name = "REVENUE_OPERATIONS"
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_revenue_operations_all_schemas" {
  account_role_name = snowflake_account_role.dbt_rw.name
  privileges        = ["USAGE"]
  
  on_schema {
    all_schemas_in_database = "REVENUE_OPERATIONS"
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_revenue_operations_future_schemas" {
  account_role_name = snowflake_account_role.dbt_rw.name
  privileges        = ["USAGE"]
  
  on_schema {
    future_schemas_in_database = "REVENUE_OPERATIONS"
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_revenue_operations_all_tables" {
  account_role_name = snowflake_account_role.dbt_rw.name
  privileges        = ["SELECT"]
  
  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_database        = "REVENUE_OPERATIONS"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_revenue_operations_future_tables" {
  account_role_name = snowflake_account_role.dbt_rw.name
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_database        = "REVENUE_OPERATIONS"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_revenue_operations_all_views" {
  account_role_name = snowflake_account_role.dbt_rw.name
  privileges        = ["SELECT"]
  
  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_database        = "REVENUE_OPERATIONS"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_revenue_operations_future_views" {
  account_role_name = snowflake_account_role.dbt_rw.name
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_database        = "REVENUE_OPERATIONS"
    }
  }
}