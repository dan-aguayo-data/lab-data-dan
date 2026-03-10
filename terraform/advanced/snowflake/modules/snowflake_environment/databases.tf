# =================
# DATABASES & SCHEMAS
# =================

locals {
  # Add environment suffix to database names
  env_suffix = upper(var.environment)
  
  # Flatten schemas for iteration
  database_schemas = flatten([
    for db_key, db in var.databases : [
      for schema in db.schemas : {
        database_key        = db_key
        database_name       = "${db_key}_${local.env_suffix}"
        schema_name         = schema
        comment             = db.comment
        data_retention_days = coalesce(db.data_retention_days, var.data_retention_days)
      }
    ]
  ])
}

# =================
# DATABASES - PROTECTED
# =================
# For PROD: prevent_destroy = true

resource "snowflake_database" "databases_protected" {
  for_each = var.protect_databases ? var.databases : {}
  
  name                        = "${each.key}_${local.env_suffix}"
  comment                     = "${each.value.comment} - ${upper(var.environment)}"
  data_retention_time_in_days = coalesce(each.value.data_retention_days, var.data_retention_days)
  
  lifecycle {
    prevent_destroy = true
  }
}

# =================
# DATABASES - UNPROTECTED
# =================
# For DEV/UAT: prevent_destroy = false

resource "snowflake_database" "databases_unprotected" {
  for_each = var.protect_databases ? {} : var.databases
  
  name                        = "${each.key}_${local.env_suffix}"
  comment                     = "${each.value.comment} - ${upper(var.environment)}"
  data_retention_time_in_days = coalesce(each.value.data_retention_days, var.data_retention_days)
}

# =================
# SCHEMAS
# =================

locals {
  # Merge protected and unprotected databases
  all_databases = merge(
    snowflake_database.databases_protected,
    snowflake_database.databases_unprotected
  )
}

resource "snowflake_schema" "schemas" {
  for_each = {
    for item in local.database_schemas :
    "${item.database_name}.${item.schema_name}" => item
  }
  
  database = local.all_databases[each.value.database_key].name
  name     = each.value.schema_name
  comment  = "Schema ${each.value.schema_name} in ${each.value.database_name}"
  
  data_retention_time_in_days = each.value.data_retention_days
}
