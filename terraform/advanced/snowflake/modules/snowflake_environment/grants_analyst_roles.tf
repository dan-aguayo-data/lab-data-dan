# =================
# ANALYST ROLES - DATABASE GRANTS
# =================

locals {
  # All schemas formatted for analyst grants (same pattern as service accounts)
  all_schemas_list = [
    for item in local.database_schemas :
    { database = item.database_name, schema = item.schema_name, database_key = item.database_key }
  ]
  
  # Non-LANDING schemas for analyst_ro and analyst_rw
  non_landing_schemas_list = [
    for item in local.database_schemas :
    { database = item.database_name, schema = item.schema_name, database_key = item.database_key }
    if !startswith(item.database_key, "LANDING_")
  ]
}

# =================
# READ-ONLY ROLES (analyst_ro) - No LANDING access
# =================

resource "snowflake_grant_privileges_to_account_role" "analyst_ro_database" {
  for_each = {
    for db_key, db_value in local.all_databases :
    db_key => db_value
    if !startswith(db_key, "LANDING_")
  }

  account_role_name = local.analyst_ro_role_name
  privileges        = ["USAGE", "MONITOR"]

  on_account_object {
    object_type = "DATABASE"
    object_name = each.value.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "analyst_ro_schema" {
  for_each = {
    for item in local.non_landing_schemas_list :
    "${item.database}.${item.schema}" => item
  }

  account_role_name = local.analyst_ro_role_name
  privileges        = ["USAGE", "MONITOR"]

  on_schema {
    schema_name = "\"${each.value.database}\".\"${each.value.schema}\""
  }

  depends_on = [snowflake_schema.schemas]
}

resource "snowflake_grant_privileges_to_account_role" "analyst_ro_future_tables" {
  for_each = {
    for item in local.non_landing_schemas_list :
    "${item.database}.${item.schema}" => item
  }

  account_role_name = local.analyst_ro_role_name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }

  depends_on = [snowflake_schema.schemas]
}

resource "snowflake_grant_privileges_to_account_role" "analyst_ro_future_views" {
  for_each = {
    for item in local.non_landing_schemas_list :
    "${item.database}.${item.schema}" => item
  }

  account_role_name = local.analyst_ro_role_name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }

  depends_on = [snowflake_schema.schemas]
}

resource "snowflake_grant_privileges_to_account_role" "analyst_ro_warehouse" {
  account_role_name = local.analyst_ro_role_name
  privileges        = ["USAGE", "OPERATE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = var.analytics_warehouse_name
  }
}

# =================
# SECURITY READ-ONLY ROLES (analyst_sec_ro) - Includes LANDING access
# =================

resource "snowflake_grant_privileges_to_account_role" "analyst_sec_ro_database" {
  for_each = local.all_databases

  account_role_name = local.analyst_sec_ro_role_name
  privileges        = ["USAGE", "MONITOR"]

  on_account_object {
    object_type = "DATABASE"
    object_name = each.value.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "analyst_sec_ro_schema" {
  for_each = {
    for item in local.all_schemas_list :
    "${item.database}.${item.schema}" => item
  }

  account_role_name = local.analyst_sec_ro_role_name
  privileges        = ["USAGE", "MONITOR"]

  on_schema {
    schema_name = "\"${each.value.database}\".\"${each.value.schema}\""
  }

  depends_on = [snowflake_schema.schemas]
}

resource "snowflake_grant_privileges_to_account_role" "analyst_sec_ro_future_tables" {
  for_each = {
    for item in local.all_schemas_list :
    "${item.database}.${item.schema}" => item
  }

  account_role_name = local.analyst_sec_ro_role_name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }

  depends_on = [snowflake_schema.schemas]
}

resource "snowflake_grant_privileges_to_account_role" "analyst_sec_ro_future_views" {
  for_each = {
    for item in local.all_schemas_list :
    "${item.database}.${item.schema}" => item
  }

  account_role_name = local.analyst_sec_ro_role_name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }

  depends_on = [snowflake_schema.schemas]
}

resource "snowflake_grant_privileges_to_account_role" "analyst_sec_ro_warehouse" {
  account_role_name = local.analyst_sec_ro_role_name
  privileges        = ["USAGE", "OPERATE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = var.analytics_warehouse_name
  }
}

# =================
# READ-WRITE ROLES (analyst_rw) - DEV Only, No LANDING access
# =================

resource "snowflake_grant_privileges_to_account_role" "analyst_rw_database" {
  for_each = var.environment == "dev" ? {
    for db_key, db_value in local.all_databases :
    db_key => db_value
    if !startswith(db_key, "LANDING_")
  } : {}

  account_role_name = local.analyst_rw_role_name
  privileges        = ["USAGE", "MONITOR"]

  on_account_object {
    object_type = "DATABASE"
    object_name = each.value.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "analyst_rw_schema" {
  for_each = var.environment == "dev" ? {
    for item in local.non_landing_schemas_list :
    "${item.database}.${item.schema}" => item
  } : {}

  account_role_name = local.analyst_rw_role_name
  privileges        = ["USAGE", "MONITOR", "CREATE TABLE", "CREATE VIEW"]

  on_schema {
    schema_name = "\"${each.value.database}\".\"${each.value.schema}\""
  }

  depends_on = [snowflake_schema.schemas]
}

resource "snowflake_grant_privileges_to_account_role" "analyst_rw_future_tables" {
  for_each = var.environment == "dev" ? {
    for item in local.non_landing_schemas_list :
    "${item.database}.${item.schema}" => item
  } : {}

  account_role_name = local.analyst_rw_role_name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }

  depends_on = [snowflake_schema.schemas]
}

resource "snowflake_grant_privileges_to_account_role" "analyst_rw_future_views" {
  for_each = var.environment == "dev" ? {
    for item in local.non_landing_schemas_list :
    "${item.database}.${item.schema}" => item
  } : {}

  account_role_name = local.analyst_rw_role_name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }

  depends_on = [snowflake_schema.schemas]
}

resource "snowflake_grant_privileges_to_account_role" "analyst_rw_warehouse" {
  count = var.environment == "dev" ? 1 : 0

  account_role_name = local.analyst_rw_role_name
  privileges        = ["USAGE", "OPERATE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = var.analytics_warehouse_name
  }
  
}

