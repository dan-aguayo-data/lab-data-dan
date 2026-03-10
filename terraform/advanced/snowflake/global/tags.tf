# -----------------------------------------------------------------------------
# TAG: ENVIRONMENT
# Purpose: Track which environment an object belongs to
# Usage: Applied to databases, schemas, warehouses
# -----------------------------------------------------------------------------
resource "snowflake_tag" "environment" {
  name           = "ENVIRONMENT"
  database       = snowflake_database.governance.name
  schema         = snowflake_schema.tags.name
  comment        = "Environment classification: DEV, UAT, or PROD"
  
  allowed_values = ["DEV", "UAT", "PROD"]
  
  depends_on = [snowflake_schema.tags]
}

# -----------------------------------------------------------------------------
# TAG: DATA_PII
# Purpose: Classify whether data contains sensitive information
# Usage: Applied to schemas, tables, and views
# -----------------------------------------------------------------------------
resource "snowflake_tag" "data_sensitivity" {
  name           = "DATA_SENSITIVITY"
  database       = snowflake_database.governance.name
  schema         = snowflake_schema.tags.name
  comment        = "Data sensitivity classification: SENSITIVE, NON_SENSITIVE, or PII"

  allowed_values = ["SENSITIVE", "NON_SENSITIVE", "PII","NON_PII"]

  depends_on = [snowflake_schema.tags]
}

# -----------------------------------------------------------------------------
# TAG: DATA_SENSITIVITY
# Purpose: Classify whether data contains sensitive information
# Usage: Applied to schemas, tables, and views
# -----------------------------------------------------------------------------
resource "snowflake_tag" "data_pii" {
  name           = "DATA_PII"
  database       = snowflake_database.governance.name
  schema         = snowflake_schema.tags.name
  comment        = "Data sensitivity classification: SENSITIVE, NON_SENSITIVE, or PII"

  allowed_values = ["SENSITIVE", "NON_SENSITIVE", "PII","NON_PII"]

  depends_on = [snowflake_schema.tags]
}

# -----------------------------------------------------------------------------
# TAG: CONFIDENTIALITY_LEVEL
# Purpose: Fine-grained confidentiality classification for sensitive data
# Usage: Applied to tables, views, and columns containing sensitive data
# Classification levels:
#   C-1: Public data (low sensitivity)
#   C-2: Internal use only (moderate sensitivity)
#   C-3: Confidential (high sensitivity, e.g., customer PII)
#   C-4: Restricted (very high sensitivity, e.g., financial data, SSN)
#   C-5: Highly Restricted (critical data, e.g., payment card data, health records)
# -----------------------------------------------------------------------------
resource "snowflake_tag" "confidentiality_level" {
  name           = "CONFIDENTIALITY_LEVEL"
  database       = snowflake_database.governance.name
  schema         = snowflake_schema.tags.name
  comment        = "Confidentiality level: C-1 (Public) through C-5 (Highly Restricted)"
  
  allowed_values = ["C-1", "C-2", "C-3", "C-4", "C-5", "C-4-SILVER", "C-4-GOLD"]
  
  depends_on = [snowflake_schema.tags]
}

# -----------------------------------------------------------------------------
# TAG: DATA_OWNER
# Purpose: Track who owns/is responsible for the data
# Usage: Applied to databases and schemas
# -----------------------------------------------------------------------------
resource "snowflake_tag" "data_owner" {
  name           = "DATA_OWNER"
  database       = snowflake_database.governance.name
  schema         = snowflake_schema.tags.name
  comment        = "Data owner team or department"
  
  depends_on = [snowflake_schema.tags]
}

# -----------------------------------------------------------------------------
# TAG: PII_TYPE
# Purpose: Classify type of personally identifiable information
# Usage: Applied to columns containing PII
# -----------------------------------------------------------------------------
resource "snowflake_tag" "pii_type" {
  name           = "PII_TYPE"
  database       = snowflake_database.governance.name
  schema         = snowflake_schema.tags.name
  comment        = "Type of PII contained in column"
  
  allowed_values = [
    "NONE",
    "NAME",
    "EMAIL",
    "PHONE",
    "ADDRESS",
    "LOCATION",
    "DOB",
    "SSN",
    "FINANCIAL",
    "HEALTH",
    "BIOMETRIC",
    "MIXED"
  ]
  
  depends_on = [snowflake_schema.tags]
}

# -----------------------------------------------------------------------------
# TAG: RETENTION_PERIOD
# Purpose: Data retention policy in days
# Usage: Applied to tables and schemas
# -----------------------------------------------------------------------------
resource "snowflake_tag" "retention_period" {
  name           = "RETENTION_PERIOD"
  database       = snowflake_database.governance.name
  schema         = snowflake_schema.tags.name
  comment        = "Data retention period in days"
  
  allowed_values = ["30", "90", "180", "365", "730", "2555", "INDEFINITE"]
  
  depends_on = [snowflake_schema.tags]
}

# -----------------------------------------------------------------------------
# TAG: SECURITY_STRATEGY
# Purpose: Define the security strategy applied to sensitive data
# Usage: Applied to columns containing sensitive data
# Strategies:
#   MASKING: Dynamic data masking (partial or full)
#   HASHED: One-way hash (SHA256, etc.)
#   ENCRYPTED: Reversible encryption
#   NONE: No security strategy applied
# -----------------------------------------------------------------------------
resource "snowflake_tag" "security_strategy" {
  name           = "SECURITY_STRATEGY"
  database       = snowflake_database.governance.name
  schema         = snowflake_schema.tags.name
  comment        = "Security strategy applied to column: MASKING, HASHED, ENCRYPTED, or NONE"
  
  allowed_values = ["MASKED", "HASHED", "ENCRYPTED", "NONE"]
  
  depends_on = [snowflake_schema.tags]
}


# -----------------------------------------------------------------------------
# OUTPUTS
# -----------------------------------------------------------------------------
output "tag_environment" {
  description = "Fully qualified name of ENVIRONMENT tag"
  value       = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\".\"${snowflake_tag.environment.name}\""
}

output "tag_data_sensitivity" {
  description = "Fully qualified name of DATA_SENSITIVITY tag"
  value       = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\".\"${snowflake_tag.data_sensitivity.name}\""
}

output "tag_confidentiality_level" {
  description = "Fully qualified name of CONFIDENTIALITY_LEVEL tag"
  value       = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\".\"${snowflake_tag.confidentiality_level.name}\""
}

output "tag_pii_type" {
  description = "Fully qualified name of PII_TYPE tag"
  value       = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\".\"${snowflake_tag.pii_type.name}\""
}

output "tag_retention_period" {
  description = "Fully qualified name of RETENTION_PERIOD tag"
  value       = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\".\"${snowflake_tag.retention_period.name}\""
}

output "tag_security_strategy" {
  description = "Fully qualified name of SECURITY_STRATEGY tag"
  value       = "\"${snowflake_database.governance.name}\".\"${snowflake_schema.tags.name}\".\"${snowflake_tag.security_strategy.name}\""
}