# -----------------------------------------------------------------------------
# GOVERNANCE DATABASE
# -----------------------------------------------------------------------------
resource "snowflake_database" "governance" {
  name                        = "EFTSURE_GOVERNANCE"
  comment                     = "Central governance database for tags, masking policies, and row access policies"
  data_retention_time_in_days = 1
  
  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------------------------------------------------------
# SCHEMAS
# -----------------------------------------------------------------------------
resource "snowflake_schema" "tags" {
  database = snowflake_database.governance.name
  name     = "TAGS"
  comment  = "Schema containing all Snowflake tags for data governance"
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "snowflake_schema" "masking_policies" {
  database = snowflake_database.governance.name
  name     = "MASKING_POLICIES"
  comment  = "Schema for dynamic data masking policies"
  
  depends_on = [snowflake_database.governance]
}

resource "snowflake_schema" "monitoring" {
  database = snowflake_database.governance.name
  name     = "MONITORING"
  comment  = "Schema for monitoring and auditing objects"
  
  depends_on = [snowflake_database.governance]
}

resource "snowflake_schema" "security_views" {
  database = snowflake_database.governance.name
  name     = "SECURITY"
  comment  = "Schema for cybersecurity monitoring and audit views"
  
  depends_on = [snowflake_database.governance]
}