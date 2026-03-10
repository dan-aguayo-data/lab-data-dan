resource "snowflake_grant_account_role" "security_role_to_sysadmin" {
  role_name        = "SF_CYBERSECURITY_GLOBAL_RO"
  parent_role_name = "SYSADMIN"
}
