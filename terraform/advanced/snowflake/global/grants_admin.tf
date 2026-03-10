# ============================================================
# SF_ADMIN - Role Hierarchy
# ============================================================
# SF_ADMIN role exists outside Terraform
# Grant it to ACCOUNTADMIN for role hierarchy

resource "snowflake_grant_account_role" "sf_admin_to_accountadmin" {
  role_name        = "SF_ADMIN"
  parent_role_name = "ACCOUNTADMIN"
}
