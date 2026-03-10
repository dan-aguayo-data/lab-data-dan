# =============================================================================
# SNOWFLAKE PROVIDER VARIABLES (set via environment variables)
# =============================================================================

variable "snowflake_organization" {
  description = "Snowflake organization name"
  type        = string
}

variable "snowflake_account_name" {
  description = "Snowflake account name (locator)"
  type        = string
}

variable "snowflake_account" {
  description = "Snowflake account identifier"
  type        = string
}

variable "snowflake_user" {
  description = "Snowflake user for Terraform"
  type        = string
}

variable "snowflake_role" {
  description = "Snowflake role for Terraform"
  type        = string
}

# =============================================================================
# AWS CONFIGURATION (set via environment variables)
# =============================================================================

variable "aws_region" {
  description = "AWS region for provider"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

# =============================================================================
# SNOWFLAKE TARGET CONFIGURATION
# =============================================================================

variable "snowflake_database" {
  description = "Snowflake database for landing data"
  type        = string
}

variable "snowflake_schema" {
  description = "Snowflake schema for Snowpipe objects"
  type        = string
}

# =============================================================================
# S3 BUCKETS CONFIGURATION (multi-bucket support)
# =============================================================================

variable "s3_buckets" {
  description = <<-EOT
    Map of S3 buckets to ingest from. Each bucket gets its own stage and pipe.
    Key is used for naming resources (e.g., "mssql_exports" -> STG_MSSQL_EXPORTS).
    
    Example:
    s3_buckets = {
      mssql_exports = {
        name   = "eftsure-mssql-exports-dw"
        prefix = "exports/"
        region = "ap-southeast-2"  # Optional, defaults to var.aws_region
      }
      europe_data = {
        name   = "eftsure-europe-exports"
        prefix = "data/"
        region = "eu-west-1"
      }
    }
  EOT
  type = map(object({
    name   = string
    prefix = string
    region = optional(string)
  }))
}

# =============================================================================
# SNOWPIPE OBJECT NAMES
# =============================================================================

variable "landing_table_name" {
  description = "Name of the raw landing table"
  type        = string
  default     = "RAW_EXPORTS"
}

variable "file_format_name" {
  description = "Name of the file format"
  type        = string
  default     = "FF_CSV_PIPE_GZIP"
}

variable "storage_integration_name" {
  description = "Name of the storage integration (leave empty for auto-generated)"
  type        = string
  default     = ""
}

# =============================================================================
# LANDING TABLE CONFIGURATION
# =============================================================================

variable "max_columns" {
  description = "Maximum number of data columns in landing table (COL_1 to COL_N)"
  type        = number
  default     = 150
}

# =============================================================================
# FILE FORMAT CONFIGURATION
# =============================================================================

variable "field_delimiter" {
  description = "Field delimiter in CSV files"
  type        = string
  default     = "|"
}

variable "skip_header" {
  description = "Number of header rows to skip"
  type        = number
  default     = 0
}

variable "null_if" {
  description = "Strings to interpret as NULL"
  type        = list(string)
  default     = ["", "NULL", "null", "\\N"]
}

# =============================================================================
# DATA RETENTION / CLEANUP
# =============================================================================

variable "cleanup_enabled" {
  description = "Enable the cleanup task"
  type        = bool
  default     = true
}

variable "cleanup_retention_days" {
  description = "Number of days to retain data in RAW_EXPORTS table"
  type        = number
  default     = 7
}

variable "cleanup_warehouse" {
  description = "Warehouse for cleanup task"
  type        = string
}

variable "cleanup_cron_schedule" {
  description = "Cron schedule for cleanup task (without 'USING CRON' prefix)"
  type        = string
  default     = "0 2 * * * UTC"
}

# =============================================================================
# NAMING / TAGGING
# =============================================================================

variable "environment" {
  description = "Environment name (dev, uat, prod)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "bcp-snowpipe"
}

variable "tags" {
  description = "Additional tags for AWS resources"
  type        = map(string)
  default     = {}
}
