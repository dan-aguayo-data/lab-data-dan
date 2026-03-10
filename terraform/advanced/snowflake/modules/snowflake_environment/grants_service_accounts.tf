# =================
# SERVICE ACCOUNT GRANTS
# =================
# Connect global service accounts to this environment's databases

locals {
  # Non-LANDING databases (STAGING, DWH_MART)
  non_landing_databases = {
    for k, v in local.all_databases : k => v
    if !startswith(k, "LANDING_")
  }
  
  # LANDING databases
  landing_databases = {
    for k, v in local.all_databases : k => v
    if startswith(k, "LANDING_")
  }
  
  # Data mart databases (DWH_MART)
  data_mart_databases = [
    for k, v in local.all_databases : v.name
    if startswith(k, "DWH_MART")
  ]
  
  # Non-LANDING schemas
  non_landing_schemas = [
    for item in local.database_schemas :
    { database = item.database_name, schema = item.schema_name }
    if !startswith(item.database_key, "LANDING_")
  ]
  
  # LANDING schemas
  landing_schemas = [
    for item in local.database_schemas :
    { database = item.database_name, schema = item.schema_name }
    if startswith(item.database_key, "LANDING_")
  ]
  
  # Data mart schemas
  data_mart_schemas = [
    for item in local.database_schemas :
    { database = item.database_name, schema = item.schema_name }
    if startswith(item.database_key, "DWH_MART")
  ]
}

# ============================================================
# DBT ROLE GRANTS
# ============================================================

# Full access: Non-LANDING databases
resource "snowflake_grant_privileges_to_account_role" "dbt_non_landing_db" {
  for_each = local.non_landing_databases
  
  account_role_name = var.dbt_role_name
  privileges        = ["USAGE", "MONITOR", "CREATE SCHEMA"]
  
  on_account_object {
    object_type = "DATABASE"
    object_name = each.value.name
  }

  depends_on = [snowflake_schema.schemas]  
}

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

  depends_on = [snowflake_schema.schemas]  

}

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
  depends_on = [snowflake_schema.schemas]  
}

resource "snowflake_grant_privileges_to_account_role" "dbt_non_landing_future_views" {
  for_each = {
    for item in local.non_landing_schemas :
    "${item.database}.${item.schema}" => item
  }
  
  account_role_name = var.dbt_role_name
  privileges        = ["SELECT", "REFERENCES"]
  
  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }

  depends_on = [snowflake_schema.schemas]  
}

# Read-only: LANDING databases
resource "snowflake_grant_privileges_to_account_role" "dbt_landing_db" {
  for_each = local.landing_databases
  
  account_role_name = var.dbt_role_name
  privileges        = ["USAGE", "MONITOR","CREATE SCHEMA"]
  
  on_account_object {
    object_type = "DATABASE"
    object_name = each.value.name
  }

  depends_on = [snowflake_schema.schemas]  

}

resource "snowflake_grant_privileges_to_account_role" "dbt_landing_schema" {
  for_each = {
    for item in local.landing_schemas :
    "${item.database}.${item.schema}" => item
  }
  
  account_role_name = var.dbt_role_name
  privileges        = ["USAGE","CREATE TABLE", "CREATE VIEW"]
  
  on_schema {
    schema_name = "\"${each.value.database}\".\"${each.value.schema}\""
  }

  depends_on = [snowflake_schema.schemas]  

}

resource "snowflake_grant_privileges_to_account_role" "dbt_landing_future_tables" {
  for_each = {
    for item in local.landing_schemas :
    "${item.database}.${item.schema}" => item
  }
  
  account_role_name = var.dbt_role_name
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }

  depends_on = [snowflake_schema.schemas]  

}

resource "snowflake_grant_privileges_to_account_role" "dbt_landing_existing_tables" {
  for_each = {
    for item in local.landing_schemas :
    "${item.database}.${item.schema}" => item
  }

  account_role_name = var.dbt_role_name
  privileges        = ["SELECT"]

  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }

  depends_on = [snowflake_schema.schemas]
}



# ============================================================
# FIVETRAN ROLE GRANTS
# ============================================================

# Write access: LANDING databases
resource "snowflake_grant_privileges_to_account_role" "fivetran_landing_db" {
  for_each = local.landing_databases
  
  account_role_name = var.fivetran_role_name
  privileges        = ["USAGE", "MONITOR", "CREATE SCHEMA"]
  
  on_account_object {
    object_type = "DATABASE"
    object_name = each.value.name
  }

  depends_on = [snowflake_schema.schemas]  

}

resource "snowflake_grant_privileges_to_account_role" "fivetran_landing_schema" {
  for_each = {
    for item in local.landing_schemas :
    "${item.database}.${item.schema}" => item
  }
  
  account_role_name = var.fivetran_role_name
  privileges        = ["USAGE", "MONITOR", "CREATE TABLE", "CREATE VIEW", "CREATE STAGE", "CREATE FILE FORMAT", "CREATE PIPE"]
  
  on_schema {
    schema_name = "\"${each.value.database}\".\"${each.value.schema}\""
  }

  depends_on = [snowflake_schema.schemas]  

}

resource "snowflake_grant_privileges_to_account_role" "fivetran_landing_future_tables" {
  for_each = {
    for item in local.landing_schemas :
    "${item.database}.${item.schema}" => item
  }
  
  account_role_name = var.fivetran_role_name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]
  
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }

  depends_on = [snowflake_schema.schemas]  

}

# ============================================================
# POWER BI ROLE GRANTS
# ============================================================

# Read-only: DWH_MART databases
resource "snowflake_grant_privileges_to_account_role" "powerbi_datamart_db" {
  for_each = toset(local.data_mart_databases)
  
  account_role_name = var.powerbi_role_name
  privileges        = ["USAGE", "MONITOR"]
  
  on_account_object {
    object_type = "DATABASE"
    object_name = each.value
  }


}

resource "snowflake_grant_privileges_to_account_role" "powerbi_datamart_schema" {
  for_each = {
    for item in local.data_mart_schemas :
    "${item.database}.${item.schema}" => item
  }
  
  account_role_name = var.powerbi_role_name
  privileges        = ["USAGE"]
  
  on_schema {
    schema_name = "\"${each.value.database}\".\"${each.value.schema}\""
  }

  depends_on = [snowflake_schema.schemas]  

}

resource "snowflake_grant_privileges_to_account_role" "powerbi_datamart_future_tables" {
  for_each = {
    for item in local.data_mart_schemas :
    "${item.database}.${item.schema}" => item
  }
  
  account_role_name = var.powerbi_role_name
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }

  depends_on = [snowflake_schema.schemas]  

}

resource "snowflake_grant_privileges_to_account_role" "powerbi_datamart_future_views" {
  for_each = {
    for item in local.data_mart_schemas :
    "${item.database}.${item.schema}" => item
  }
  
  account_role_name = var.powerbi_role_name
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema          = "\"${each.value.database}\".\"${each.value.schema}\""
    }
  }

  depends_on = [snowflake_schema.schemas]  

}
