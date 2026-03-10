
# -----------------------------------------------------------------------------
# SYSADMIN - TAG APPLY PRIVILEGES
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "tags_to_sysadmin" {
  account_role_name = "SYSADMIN"
  privileges        = ["APPLY"]
  
  on_schema_object {
    object_type = "TAG"
    object_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\".\"${snowflake_tag.environment.name}\""
  }
  
  depends_on = [snowflake_tag.environment]
}

resource "snowflake_grant_privileges_to_account_role" "sensitivity_to_sysadmin" {
  account_role_name = "SYSADMIN"
  privileges        = ["APPLY"]
  
  on_schema_object {
    object_type = "TAG"
    object_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\".\"${snowflake_tag.data_sensitivity.name}\""
  }
  
  depends_on = [snowflake_tag.data_sensitivity]
}

resource "snowflake_grant_privileges_to_account_role" "data_pii_to_sysadmin" {
  account_role_name = "SYSADMIN"
  privileges        = ["APPLY"]
  
  on_schema_object {
    object_type = "TAG"
    object_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\".\"${snowflake_tag.data_pii.name}\""
  }
  
  depends_on = [snowflake_tag.data_pii]
}


resource "snowflake_grant_privileges_to_account_role" "confidentiality_to_sysadmin" {
  account_role_name = "SYSADMIN"
  privileges        = ["APPLY"]
  
  on_schema_object {
    object_type = "TAG"
    object_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\".\"${snowflake_tag.confidentiality_level.name}\""
  }
  
  depends_on = [snowflake_tag.confidentiality_level]
}

resource "snowflake_grant_privileges_to_account_role" "pii_to_sysadmin" {
  account_role_name = "SYSADMIN"
  privileges        = ["APPLY"]
  
  on_schema_object {
    object_type = "TAG"
    object_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\".\"${snowflake_tag.pii_type.name}\""
  }
  
  depends_on = [snowflake_tag.pii_type]
}

# -----------------------------------------------------------------------------
# SVC_ROLE_DBT_RW - DATABASE AND SCHEMA ACCESS
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "governance_db_to_dbt" {
  account_role_name = "SVC_ROLE_DBT_RW"
  privileges        = ["USAGE"]
  
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.governance.name
  }
  
  depends_on = [snowflake_database.governance]
}

resource "snowflake_grant_privileges_to_account_role" "tags_schema_to_dbt" {
  account_role_name = "SVC_ROLE_DBT_RW"
  privileges        = ["USAGE"]
  
  on_schema {
    schema_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\""
  }
  
  depends_on = [snowflake_schema.tags]
}

resource "snowflake_grant_privileges_to_account_role" "security_schema_to_dbt" {
  account_role_name = "SVC_ROLE_DBT_RW"
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW", "CREATE DYNAMIC TABLE"]
  
  on_schema {
    schema_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.security_views.name}\""
  }
  
  depends_on = [snowflake_schema.security_views]
}

resource "snowflake_grant_privileges_to_account_role" "monitoring_schema_to_dbt" {
  account_role_name = "SVC_ROLE_DBT_RW"
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW", "CREATE DYNAMIC TABLE"]
  
  on_schema {
    schema_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.monitoring.name}\""
  }
  
  depends_on = [snowflake_schema.monitoring,snowflake_grant_account_role.security_role_to_sysadmin]
}





# -----------------------------------------------------------------------------
# SVC_ROLE_DBT_RW - TAG APPLY PRIVILEGES
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "tag_environment_to_dbt" {
  account_role_name = "SVC_ROLE_DBT_RW"
  privileges        = ["APPLY"]
  
  on_schema_object {
    object_type = "TAG"
    object_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\".\"${snowflake_tag.environment.name}\""
  }
  
  depends_on = [snowflake_tag.environment]
}

resource "snowflake_grant_privileges_to_account_role" "tag_sensitivity_to_dbt" {
  account_role_name = "SVC_ROLE_DBT_RW"
  privileges        = ["APPLY"]
  
  on_schema_object {
    object_type = "TAG"
    object_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\".\"${snowflake_tag.data_sensitivity.name}\""
  }
  
  depends_on = [snowflake_tag.data_sensitivity]
}

resource "snowflake_grant_privileges_to_account_role" "data_pii_to_dbt" {
  account_role_name = "SVC_ROLE_DBT_RW"
  privileges        = ["APPLY"]
  
  on_schema_object {
    object_type = "TAG"
    object_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\".\"${snowflake_tag.data_pii.name}\""
  }
  
  depends_on = [snowflake_tag.data_pii]
}

resource "snowflake_grant_privileges_to_account_role" "tag_confidentiality_to_dbt" {
  account_role_name = "SVC_ROLE_DBT_RW"
  privileges        = ["APPLY"]
  
  on_schema_object {
    object_type = "TAG"
    object_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\".\"${snowflake_tag.confidentiality_level.name}\""
  }
  
  depends_on = [snowflake_tag.confidentiality_level]
}

resource "snowflake_grant_privileges_to_account_role" "tag_pii_type_to_dbt" {
  account_role_name = "SVC_ROLE_DBT_RW"
  privileges        = ["APPLY"]
  
  on_schema_object {
    object_type = "TAG"
    object_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\".\"${snowflake_tag.pii_type.name}\""
  }
  
  depends_on = [snowflake_tag.pii_type]
}

resource "snowflake_grant_privileges_to_account_role" "tag_retention_to_dbt" {
  account_role_name = "SVC_ROLE_DBT_RW"
  privileges        = ["APPLY"]
  
  on_schema_object {
    object_type = "TAG"
    object_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\".\"${snowflake_tag.retention_period.name}\""
  }
  
  depends_on = [snowflake_tag.retention_period]
}

resource "snowflake_grant_privileges_to_account_role" "tag_data_owner_to_dbt" {
  account_role_name = "SVC_ROLE_DBT_RW"
  privileges        = ["APPLY"]
  
  on_schema_object {
    object_type = "TAG"
    object_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\".\"${snowflake_tag.data_owner.name}\""
  }
  
  depends_on = [snowflake_tag.data_owner]
}

# -----------------------------------------------------------------------------
# SVC_ROLE_DBT_RW - SNOWFLAKE DATABASE ACCESS (ACCOUNT_USAGE)
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "snowflake_db_to_dbt" {
  account_role_name = "SVC_ROLE_DBT_RW"
  privileges        = ["IMPORTED PRIVILEGES"]
  
  on_account_object {
    object_type = "DATABASE"
    object_name = "SNOWFLAKE"
  }
}

# -----------------------------------------------------------------------------
# SVC_ROLE_DBT_RW - FUTURE GRANTS ON SECURITY SCHEMA
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "security_future_tables_to_dbt" {
  account_role_name = "SVC_ROLE_DBT_RW"
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]
  
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.security_views.name}\""
    }
  }
  
  depends_on = [snowflake_schema.security_views]
}

resource "snowflake_grant_privileges_to_account_role" "security_future_views_to_dbt" {
  account_role_name = "SVC_ROLE_DBT_RW"
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema          = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.security_views.name}\""
    }
  }
  
  depends_on = [snowflake_schema.security_views]
}

# -----------------------------------------------------------------------------
# SF_CYBERSECURITY_GLOBAL_RO - READ-ONLY ACCESS TO GOVERNANCE DATABASE
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "governance_db_to_cybersecurity" {
  account_role_name = "SF_CYBERSECURITY_GLOBAL_RO"
  privileges        = ["USAGE"]
  
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.governance.name
  }
  
  depends_on = [snowflake_database.governance]
}

resource "snowflake_grant_privileges_to_account_role" "tags_schema_to_cybersecurity" {
  account_role_name = "SF_CYBERSECURITY_GLOBAL_RO"
  privileges        = ["USAGE"]
  
  on_schema {
    schema_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\""
  }
  
  depends_on = [snowflake_schema.tags]
}

resource "snowflake_grant_privileges_to_account_role" "security_schema_to_cybersecurity" {
  account_role_name = "SF_CYBERSECURITY_GLOBAL_RO"
  privileges        = ["USAGE"]
  
  on_schema {
    schema_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.security_views.name}\""
  }
  
  depends_on = [snowflake_schema.security_views]
}

resource "snowflake_grant_privileges_to_account_role" "monitoring_schema_to_cybersecurity" {
  account_role_name = "SF_CYBERSECURITY_GLOBAL_RO"
  privileges        = ["USAGE"]
  
  on_schema {
    schema_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.monitoring.name}\""
  }
  
  depends_on = [snowflake_schema.monitoring,snowflake_grant_account_role.security_role_to_sysadmin]
}

resource "snowflake_grant_privileges_to_account_role" "masking_schema_to_cybersecurity" {
  account_role_name = "SF_CYBERSECURITY_GLOBAL_RO"
  privileges        = ["USAGE"]
  
  on_schema {
    schema_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.masking_policies.name}\""
  }
  
  depends_on = [snowflake_schema.masking_policies]
}

# -----------------------------------------------------------------------------
# SF_CYBERSECURITY_GLOBAL_RO - SELECT ON CURRENT OBJECTS
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "tags_tables_to_cybersecurity" {
  account_role_name = "SF_CYBERSECURITY_GLOBAL_RO"
  privileges        = ["SELECT"]
  
  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\""
    }
  }
  
  depends_on = [snowflake_schema.tags]
}

resource "snowflake_grant_privileges_to_account_role" "tags_views_to_cybersecurity" {
  account_role_name = "SF_CYBERSECURITY_GLOBAL_RO"
  privileges        = ["SELECT"]
  
  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_schema          = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\""
    }
  }
  
  depends_on = [snowflake_schema.tags]
}

resource "snowflake_grant_privileges_to_account_role" "security_all_tables_to_cybersecurity" {
  account_role_name = "SF_CYBERSECURITY_GLOBAL_RO"
  privileges        = ["SELECT"]
  
  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.security_views.name}\""
    }
  }
  
  depends_on = [snowflake_schema.security_views]
}

resource "snowflake_grant_privileges_to_account_role" "security_all_views_to_cybersecurity" {
  account_role_name = "SF_CYBERSECURITY_GLOBAL_RO"
  privileges        = ["SELECT"]
  
  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_schema          = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.security_views.name}\""
    }
  }
  
  depends_on = [snowflake_schema.security_views]
}

# -----------------------------------------------------------------------------
# SF_CYBERSECURITY_GLOBAL_RO - FUTURE GRANTS FOR SECURITY SCHEMA
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "security_future_tables_to_cybersecurity" {
  account_role_name = "SF_CYBERSECURITY_GLOBAL_RO"
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.security_views.name}\""
    }
  }
  
  depends_on = [snowflake_schema.security_views]
}

resource "snowflake_grant_privileges_to_account_role" "security_future_views_to_cybersecurity" {
  account_role_name = "SF_CYBERSECURITY_GLOBAL_RO"
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema          = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.security_views.name}\""
    }
  }
  
  depends_on = [snowflake_schema.security_views]
}

# -----------------------------------------------------------------------------
# SF_CYBERSECURITY_GLOBAL_RO - FUTURE GRANTS FOR MONITORING SCHEMA
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "monitoring_future_tables_to_cybersecurity" {
  account_role_name = "SF_CYBERSECURITY_GLOBAL_RO"
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.monitoring.name}\""
    }
  }
  
  depends_on = [snowflake_schema.monitoring,snowflake_grant_account_role.security_role_to_sysadmin]  
}

resource "snowflake_grant_privileges_to_account_role" "monitoring_future_views_to_cybersecurity" {
  account_role_name = "SF_CYBERSECURITY_GLOBAL_RO"
  privileges        = ["SELECT"]
  
  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema          = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.monitoring.name}\""
    }
  }
  
  depends_on = [snowflake_schema.monitoring,snowflake_grant_account_role.security_role_to_sysadmin]
}

# -----------------------------------------------------------------------------
# SF_CYBERSECURITY_GLOBAL_RO - SNOWFLAKE DATABASE ACCESS (ACCOUNT_USAGE)
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "snowflake_db_to_cybersecurity" {
  account_role_name = "SF_CYBERSECURITY_GLOBAL_RO"
  privileges        = ["IMPORTED PRIVILEGES"]
  
  on_account_object {
    object_type = "DATABASE"
    object_name = "SNOWFLAKE"
  }
}

# -----------------------------------------------------------------------------
# SYSADMIN - SECURITY_STRATEGY TAG
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "security_strategy_to_sysadmin" {
  account_role_name = "SYSADMIN"
  privileges        = ["APPLY"]
  
  on_schema_object {
    object_type = "TAG"
    object_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\".\"${snowflake_tag.security_strategy.name}\""
  }
  
  depends_on = [snowflake_tag.security_strategy]
}

# -----------------------------------------------------------------------------
# SVC_ROLE_DBT_RW - SECURITY_STRATEGY TAG
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "tag_security_strategy_to_dbt" {
  account_role_name = "SVC_ROLE_DBT_RW"
  privileges        = ["APPLY"]
  
  on_schema_object {
    object_type = "TAG"
    object_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\".\"${snowflake_tag.security_strategy.name}\""
  }
  
  depends_on = [snowflake_tag.security_strategy]
}


# -----------------------------------------------------------------------------
# SVC_ROLE_DBT_RW - MASKING POLICY PRIVILEGES
# -----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "masking_schema_to_dbt" {
  account_role_name = "SVC_ROLE_DBT_RW"
  privileges        = ["USAGE"]
  
  on_schema {
    schema_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.masking_policies.name}\""
  }
  
  depends_on = [snowflake_schema.masking_policies]
}

# Grant APPLY on each masking policy individually
resource "snowflake_grant_privileges_to_account_role" "masking_policy_email_to_dbt" {
  account_role_name = "SVC_ROLE_DBT_RW"
  privileges        = ["APPLY"]
  
  on_schema_object {
    object_type = "MASKING POLICY"
    object_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.masking_policies.name}\".\"${snowflake_masking_policy.email_mask.name}\""
  }
  
  depends_on = [snowflake_masking_policy.email_mask]
}

resource "snowflake_grant_privileges_to_account_role" "masking_policy_full_to_dbt" {
  account_role_name = "SVC_ROLE_DBT_RW"
  privileges        = ["APPLY"]
  
  on_schema_object {
    object_type = "MASKING POLICY"
    object_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.masking_policies.name}\".\"${snowflake_masking_policy.full_mask.name}\""
  }
  
  depends_on = [snowflake_masking_policy.full_mask]
}

resource "snowflake_grant_privileges_to_account_role" "masking_policy_name_to_dbt" {
  account_role_name = "SVC_ROLE_DBT_RW"
  privileges        = ["APPLY"]
  
  on_schema_object {
    object_type = "MASKING POLICY"
    object_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.masking_policies.name}\".\"${snowflake_masking_policy.name_mask.name}\""
  }
  
  depends_on = [snowflake_masking_policy.name_mask]
}

resource "snowflake_grant_privileges_to_account_role" "masking_policy_phone_to_dbt" {
  account_role_name = "SVC_ROLE_DBT_RW"
  privileges        = ["APPLY"]
  
  on_schema_object {
    object_type = "MASKING POLICY"
    object_name = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.masking_policies.name}\".\"${snowflake_masking_policy.phone_mask.name}\""
  }
  
  depends_on = [snowflake_masking_policy.phone_mask]
}

