# =================
# EXEC ANALYST ROLE (exec_rw) - PROD ONLY
# =================
# LANDING_FP: All schemas - READ ONLY
# STAGING.EXEC_ANALYST: READ WRITE (full permissions)
# DWH_MART: All schemas - READ ONLY
#
# NOTE: These grants only apply in PROD environment
# DEV and UAT will have the role but no grants
# =================

# -----------------
# LANDING_FP - READ ONLY
# -----------------

# Database grant
resource "snowflake_grant_privileges_to_account_role" "exec_landing_fp_database" {
  for_each = var.environment == "prod" ? {
    for db_key, db_value in local.all_databases :
    db_key => db_value
    if db_key == "LANDING_FP"
  } : {}

  account_role_name = local.exec_rw_role_name
  privileges        = ["USAGE", "MONITOR"]

  on_account_object {
    object_type = "DATABASE"
    object_name = each.value.name
  }
}

# Schema grants - all schemas in LANDING_FP
resource "snowflake_grant_privileges_to_account_role" "exec_landing_fp_schema" {
  for_each = var.environment == "prod" ? {
    for item in local.all_schemas_list :
    "${item.database}.${item.schema}" => item
    if item.database_key == "LANDING_FP"
  } : {}

  account_role_name = local.exec_rw_role_name
  privileges        = ["USAGE", "MONITOR"]

  on_schema {
    schema_name = "\"${each.value.database}\".\"${each.value.schema}\""
  }

  depends_on = [snowflake_schema.schemas]
}

# Future tables - READ ONLY
resource "snowflake_grant_privileges_to_account_role" "exec_landing_fp_future_tables" {
  for_each = var.environment == "prod" ? {
    for item in local.all_schemas_list :
    "${item.database}.${item.schema}" => item
    if item.database_key == "LANDING_FP"
  } : {}

  account_role_name = local.exec_rw_role_name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }

  depends_on = [snowflake_schema.schemas]
}

# Future views - READ ONLY
resource "snowflake_grant_privileges_to_account_role" "exec_landing_fp_future_views" {
  for_each = var.environment == "prod" ? {
    for item in local.all_schemas_list :
    "${item.database}.${item.schema}" => item
    if item.database_key == "LANDING_FP"
  } : {}

  account_role_name = local.exec_rw_role_name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }

  depends_on = [snowflake_schema.schemas]
}

# -----------------
# STAGING.EXEC_ANALYST - READ WRITE
# -----------------

# Database grant
resource "snowflake_grant_privileges_to_account_role" "exec_staging_database" {
  for_each = var.environment == "prod" ? {
    for db_key, db_value in local.all_databases :
    db_key => db_value
    if db_key == "STAGING"
  } : {}

  account_role_name = local.exec_rw_role_name
  privileges        = ["USAGE", "MONITOR"]

  on_account_object {
    object_type = "DATABASE"
    object_name = each.value.name
  }
}

# Schema grant - EXEC_ANALYST only
resource "snowflake_grant_privileges_to_account_role" "exec_staging_exec_analyst_schema" {
  for_each = var.environment == "prod" ? {
    for item in local.all_schemas_list :
    "${item.database}.${item.schema}" => item
    if item.database_key == "STAGING" && item.schema == "EXEC_ANALYST"
  } : {}

  account_role_name = local.exec_rw_role_name
  privileges        = ["USAGE", "MONITOR", "CREATE TABLE", "CREATE VIEW", "CREATE STAGE", "CREATE FILE FORMAT"]

  on_schema {
    schema_name = "\"${each.value.database}\".\"${each.value.schema}\""
  }

  depends_on = [snowflake_schema.schemas]
}

# Future tables - FULL READ WRITE
resource "snowflake_grant_privileges_to_account_role" "exec_staging_exec_analyst_future_tables" {
  for_each = var.environment == "prod" ? {
    for item in local.all_schemas_list :
    "${item.database}.${item.schema}" => item
    if item.database_key == "STAGING" && item.schema == "EXEC_ANALYST"
  } : {}

  account_role_name = local.exec_rw_role_name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE", "REFERENCES"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }

  depends_on = [snowflake_schema.schemas]
}

# Future views - SELECT
resource "snowflake_grant_privileges_to_account_role" "exec_staging_exec_analyst_future_views" {
  for_each = var.environment == "prod" ? {
    for item in local.all_schemas_list :
    "${item.database}.${item.schema}" => item
    if item.database_key == "STAGING" && item.schema == "EXEC_ANALYST"
  } : {}

  account_role_name = local.exec_rw_role_name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }

  depends_on = [snowflake_schema.schemas]
}

# -----------------
# DWH_MART - READ ONLY
# -----------------

# Database grant
resource "snowflake_grant_privileges_to_account_role" "exec_dwh_mart_database" {
  for_each = var.environment == "prod" ? {
    for db_key, db_value in local.all_databases :
    db_key => db_value
    if db_key == "DWH_MART"
  } : {}

  account_role_name = local.exec_rw_role_name
  privileges        = ["USAGE", "MONITOR"]

  on_account_object {
    object_type = "DATABASE"
    object_name = each.value.name
  }
}

# Schema grants - all schemas in DWH_MART
resource "snowflake_grant_privileges_to_account_role" "exec_dwh_mart_schema" {
  for_each = var.environment == "prod" ? {
    for item in local.all_schemas_list :
    "${item.database}.${item.schema}" => item
    if item.database_key == "DWH_MART"
  } : {}

  account_role_name = local.exec_rw_role_name
  privileges        = ["USAGE", "MONITOR"]

  on_schema {
    schema_name = "\"${each.value.database}\".\"${each.value.schema}\""
  }

  depends_on = [snowflake_schema.schemas]
}

# Future tables - READ ONLY
resource "snowflake_grant_privileges_to_account_role" "exec_dwh_mart_future_tables" {
  for_each = var.environment == "prod" ? {
    for item in local.all_schemas_list :
    "${item.database}.${item.schema}" => item
    if item.database_key == "DWH_MART"
  } : {}

  account_role_name = local.exec_rw_role_name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }

  depends_on = [snowflake_schema.schemas]
}

# Future views - READ ONLY
resource "snowflake_grant_privileges_to_account_role" "exec_dwh_mart_future_views" {
  for_each = var.environment == "prod" ? {
    for item in local.all_schemas_list :
    "${item.database}.${item.schema}" => item
    if item.database_key == "DWH_MART"
  } : {}

  account_role_name = local.exec_rw_role_name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }

  depends_on = [snowflake_schema.schemas]
}

# -----------------
# WAREHOUSE ACCESS
# -----------------

resource "snowflake_grant_privileges_to_account_role" "exec_warehouse" {
  count = var.environment == "prod" ? 1 : 0

  account_role_name = local.exec_rw_role_name
  privileges        = ["USAGE", "OPERATE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = var.analytics_warehouse_name
  }
}
