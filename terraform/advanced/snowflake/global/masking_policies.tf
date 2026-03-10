# =============================================================================
# masking_policies.tf
# =============================================================================
# Dynamic data masking policies for sensitive data
# =============================================================================

# -----------------------------------------------------------------------------
# MASKING POLICY: EMAIL - Mask everything before @
# Example: john.doe@company.com -> ****@company.com
# -----------------------------------------------------------------------------
resource "snowflake_masking_policy" "email_mask" {
  name     = "EMAIL_MASK"
  database = snowflake_database.governance.name
  schema   = snowflake_schema.masking_policies.name
  
  argument {
    name = "val"
    type = "VARCHAR"
  }
  
  body = <<-EOT
    CASE
      WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SYSADMIN', 'SVC_ROLE_DBT_RW','SVC_ROLE_POWERBI_RO') THEN val
      WHEN CONTAINS(val, '@') THEN CONCAT('****', SUBSTR(val, POSITION('@' IN val)))
      ELSE '****'
    END
  EOT
  
  return_data_type = "VARCHAR"
  comment          = "Masks email address, showing only domain (****@domain.com)"
  
  depends_on = [snowflake_schema.masking_policies]
}

# -----------------------------------------------------------------------------
# MASKING POLICY: FULL MASK - Replace entire value with ****
# -----------------------------------------------------------------------------
resource "snowflake_masking_policy" "full_mask" {
  name     = "FULL_MASK"
  database = snowflake_database.governance.name
  schema   = snowflake_schema.masking_policies.name
  
  argument {
    name = "val"
    type = "VARCHAR"
  }
  
  body = <<-EOT
    CASE
      WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SYSADMIN', 'SVC_ROLE_DBT_RW','SVC_ROLE_POWERBI_RO') THEN val
      ELSE '****'
    END
  EOT
  
  return_data_type = "VARCHAR"
  comment          = "Fully masks the value with ****"
  
  depends_on = [snowflake_schema.masking_policies]
}



# -----------------------------------------------------------------------------
# MASKING POLICY: NAME - Show first initial only
# Example: John -> J****
# -----------------------------------------------------------------------------
resource "snowflake_masking_policy" "name_mask" {
  name     = "NAME_MASK"
  database = snowflake_database.governance.name
  schema   = snowflake_schema.masking_policies.name
  
  argument {
    name = "val"
    type = "VARCHAR"
  }
  
  body = <<-EOT
    CASE
      WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SYSADMIN', 'SVC_ROLE_DBT_RW','SVC_ROLE_POWERBI_RO') THEN val
      WHEN LENGTH(val) > 0 THEN CONCAT(LEFT(val, 1), '****')
      ELSE '****'
    END
  EOT
  
  return_data_type = "VARCHAR"
  comment          = "Masks name showing only first initial (J****)"
  
  depends_on = [snowflake_schema.masking_policies]
}

# -----------------------------------------------------------------------------
# MASKING POLICY: PHONE - Show last 4 digits only
# Example: +61412345678 -> ****5678
# -----------------------------------------------------------------------------
resource "snowflake_masking_policy" "phone_mask" {
  name     = "PHONE_MASK"
  database = snowflake_database.governance.name
  schema   = snowflake_schema.masking_policies.name
  
  argument {
    name = "val"
    type = "VARCHAR"
  }
  
  body = <<-EOT
    CASE
      WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SYSADMIN', 'SVC_ROLE_DBT_RW','SVC_ROLE_POWERBI_RO') THEN val
      WHEN LENGTH(val) >= 4 THEN CONCAT('****', RIGHT(val, 4))
      ELSE '****'
    END
  EOT
  
  return_data_type = "VARCHAR"
  comment          = "Masks phone number showing only last 4 digits (****5678)"
  
  depends_on = [snowflake_schema.masking_policies]
}

# -----------------------------------------------------------------------------
# OUTPUTS
# -----------------------------------------------------------------------------
output "masking_policy_email" {
  description = "Fully qualified name of EMAIL_MASK policy"
  value       = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.masking_policies.name}\".\"${snowflake_masking_policy.email_mask.name}\""
}

output "masking_policy_full" {
  description = "Fully qualified name of FULL_MASK policy"
  value       = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.masking_policies.name}\".\"${snowflake_masking_policy.full_mask.name}\""
}

output "masking_policy_name" {
  description = "Fully qualified name of NAME_MASK policy"
  value       = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.masking_policies.name}\".\"${snowflake_masking_policy.name_mask.name}\""
}

output "masking_policy_phone" {
  description = "Fully qualified name of PHONE_MASK policy"
  value       = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.masking_policies.name}\".\"${snowflake_masking_policy.phone_mask.name}\""
}