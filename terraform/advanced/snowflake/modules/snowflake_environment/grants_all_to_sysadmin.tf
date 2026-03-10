# =================
# GRANT ALL ROLES TO SYSADMIN
# =================

resource "snowflake_grant_account_role" "analyst_ro_to_sysadmin" {
  role_name        = local.analyst_ro_role_name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "analyst_sec_ro_to_sysadmin" {
  role_name        = local.analyst_sec_ro_role_name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "analyst_rw_to_sysadmin" {
  count            = var.environment == "dev" ? 1 : 0
  role_name        = local.analyst_rw_role_name
  parent_role_name = "SYSADMIN"
}
