# =================
# WAREHOUSE GRANTS - Global Service Accounts
# =================
# Service accounts get access to their designated warehouses

# DBT → DBT Warehouse
resource "snowflake_grant_privileges_to_account_role" "dbt_warehouse" {
  account_role_name = snowflake_account_role.dbt_rw.name
  privileges        = ["USAGE", "OPERATE"]
  
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.dbt.name
  }
}


resource "snowflake_grant_privileges_to_account_role" "dbt_warehouse-dev" {
  account_role_name = snowflake_account_role.dbt_rw.name
  privileges        = ["USAGE", "OPERATE"]
  
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.dbt-dev.name
  }
}



resource "snowflake_grant_privileges_to_account_role" "dbt_warehouse-uat" {
  account_role_name = snowflake_account_role.dbt_rw.name
  privileges        = ["USAGE", "OPERATE"]
  
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.dbt-uat.name
  }
}


resource "snowflake_grant_privileges_to_account_role" "dbt_warehouse-prod" {
  account_role_name = snowflake_account_role.dbt_rw.name
  privileges        = ["USAGE", "OPERATE"]
  
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.dbt-prod.name
  }
}


# Fivetran → Fivetran Warehouse
resource "snowflake_grant_privileges_to_account_role" "fivetran_warehouse" {
  account_role_name = snowflake_account_role.fivetran_rw.name
  privileges        = ["USAGE", "OPERATE"]
  
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.fivetran.name
  }
}

# PowerBI → PowerBI Warehouse
resource "snowflake_grant_privileges_to_account_role" "powerbi_warehouse" {
  account_role_name = snowflake_account_role.powerbi_ro.name
  privileges        = ["USAGE"]
  
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.powerbi.name
  }
}
