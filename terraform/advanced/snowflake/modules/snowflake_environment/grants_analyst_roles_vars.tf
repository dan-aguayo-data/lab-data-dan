
# =================
# ANALYST ROLE NAMES (Pre-existing roles, just construct the names)
# =================

locals {
  analyst_ro_role_name     = "SF_DATA_ANALYST_${local.env_suffix}_RO"
  analyst_sec_ro_role_name = "SF_DATA_ANALYST_${local.env_suffix}_SEC_RO"
  analyst_rw_role_name     = "SF_DATA_ANALYST_${local.env_suffix}_RW"
  exec_rw_role_name         = "SF_EXEC_ANALYST_PROD_RW"
}