# =================
# RSA PUBLIC KEYS FROM AWS SECRETS MANAGER
# =================


data "aws_secretsmanager_secret_version" "dbt_rsa_2" {
  secret_id = "data/dwh/snowflake/svc_dbt_rsa2"
}

data "aws_secretsmanager_secret_version" "fivetran_rsa_2" {
  secret_id = "data/dwh/snowflake/svc_fivetran_rsa2"
}

data "aws_secretsmanager_secret_version" "powerbi_rsa_2" {
  secret_id = "data/dwh/snowflake/svc_powerbi_rsa2"
}

# =================
# SERVICE ROLES
# =================

resource "snowflake_account_role" "dbt_rw" {
  name    = "SVC_ROLE_DBT_RW"
  comment = "Role for dbt transformations across all environments"
}

resource "snowflake_account_role" "fivetran_rw" {
  name    = "SVC_ROLE_FIVETRAN_RW"
  comment = "Role for Fivetran data loading across all environments"
}

resource "snowflake_account_role" "powerbi_ro" {
  name    = "SVC_ROLE_POWERBI_RO"
  comment = "Role for Power BI service principal"
}

# =================
# SERVICE USERS
# =================

resource "snowflake_service_user" "dbt" {
  name         = "SVC_DATA_DBT"
  comment      = "Service user for dbt transformations"
  disabled     = false
  display_name = "SVC_DATA_DBT"
  
  default_warehouse              = snowflake_warehouse.dbt.name
  default_role                   = snowflake_account_role.dbt_rw.name
  default_secondary_roles_option = "ALL"
  default_namespace              = "SNOWFLAKE"
  
  #rsa_public_key = data.aws_secretsmanager_secret_version.dbt_rsa_1.secret_string
  rsa_public_key_2 = jsondecode(data.aws_secretsmanager_secret_version.dbt_rsa_2.secret_string).snowflake_format
}

resource "snowflake_service_user" "fivetran" {
  name         = "SVC_DATA_FIVETRAN"
  comment      = "Service user for Fivetran data ingestion"
  disabled     = false
  display_name = "SVC_DATA_FIVETRAN"
  
  default_warehouse              = snowflake_warehouse.fivetran.name
  default_role                   = snowflake_account_role.fivetran_rw.name
  default_secondary_roles_option = "ALL"
  default_namespace              = "SNOWFLAKE"
  #rsa_public_key = data.aws_secretsmanager_secret_version.fivetran_rsa_1.secret_string
  rsa_public_key_2 = jsondecode(data.aws_secretsmanager_secret_version.fivetran_rsa_2.secret_string).snowflake_format

}

resource "snowflake_service_user" "powerbi" {
  name         = "SVC_DATA_POWERBI"
  comment      = "Service user for Power BI datasets"
  disabled     = false
  display_name = "SVC_DATA_POWERBI"
  
  default_warehouse              = snowflake_warehouse.powerbi.name
  default_role                   = snowflake_account_role.powerbi_ro.name
  default_secondary_roles_option = "ALL"
  default_namespace              = "SNOWFLAKE"
  #rsa_public_key = data.aws_secretsmanager_secret_version.powerbi_rsa_1.secret_string
  rsa_public_key_2 = jsondecode(data.aws_secretsmanager_secret_version.powerbi_rsa_2.secret_string).snowflake_format
}

# =================
# GRANT ROLES TO USERS
# =================

resource "snowflake_grant_account_role" "dbt_user_grant" {
  role_name = snowflake_account_role.dbt_rw.name
  user_name = snowflake_service_user.dbt.name
}

resource "snowflake_grant_account_role" "fivetran_user_grant" {
  role_name = snowflake_account_role.fivetran_rw.name
  user_name = snowflake_service_user.fivetran.name
}

resource "snowflake_grant_account_role" "powerbi_user_grant" {
  role_name = snowflake_account_role.powerbi_ro.name
  user_name = snowflake_service_user.powerbi.name
}

# =================
# ROLE HIERARCHY - GRANT TO SYSADMIN
# =================

resource "snowflake_grant_account_role" "dbt_to_sysadmin" {
  role_name        = snowflake_account_role.dbt_rw.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "fivetran_to_sysadmin" {
  role_name        = snowflake_account_role.fivetran_rw.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "powerbi_to_sysadmin" {
  role_name        = snowflake_account_role.powerbi_ro.name
  parent_role_name = "SYSADMIN"
}
