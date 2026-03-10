# =================
# GLOBAL OUTPUTS
# =================
# These are referenced by environments via terraform_remote_state

# =================
# SERVICE ACCOUNT OUTPUTS
# =================

output "dbt_role_name" {
  description = "DBT service role name"
  value       = snowflake_account_role.dbt_rw.name
}

output "fivetran_role_name" {
  description = "Fivetran service role name"
  value       = snowflake_account_role.fivetran_rw.name
}

output "powerbi_role_name" {
  description = "PowerBI service role name"
  value       = snowflake_account_role.powerbi_ro.name
}

output "dbt_user_name" {
  description = "DBT service user name"
  value       = snowflake_service_user.dbt.name
}

output "fivetran_user_name" {
  description = "Fivetran service user name"
  value       = snowflake_service_user.fivetran.name
}

output "powerbi_user_name" {
  description = "PowerBI service user name"
  value       = snowflake_service_user.powerbi.name
}

# =================
# WAREHOUSE OUTPUTS
# =================

output "dbt_warehouse_name" {
  description = "DBT warehouse name"
  value       = snowflake_warehouse.dbt.name
}

output "fivetran_warehouse_name" {
  description = "Fivetran warehouse name"
  value       = snowflake_warehouse.fivetran.name
}

output "powerbi_warehouse_name" {
  description = "PowerBI warehouse name"
  value       = snowflake_warehouse.powerbi.name
}

output "analytics_warehouse_name" {
  description = "Analytics warehouse name"
  value       = snowflake_warehouse.analytics.name
}

# =================
# SUMMARY OUTPUT
# =================

output "summary" {
  description = "Summary of global resources created"
  value = {
    service_accounts = {
      dbt      = snowflake_service_user.dbt.name
      fivetran = snowflake_service_user.fivetran.name
      powerbi  = snowflake_service_user.powerbi.name
    }
    warehouses = {
      dbt       = snowflake_warehouse.dbt.name
      fivetran  = snowflake_warehouse.fivetran.name
      powerbi   = snowflake_warehouse.powerbi.name
      analytics = snowflake_warehouse.analytics.name
    }
  }
}
