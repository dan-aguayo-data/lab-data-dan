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
  description = "Snowflake account identifier (e.g., su73143.ap-southeast-2)"
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
# AWS CONFIGURATION
# =============================================================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "aws_account_id" {
  description = "AWS Account ID (used for IAM role trust policy)"
  type        = string
}

# =============================================================================
# S3 BUCKET CONFIGURATION
# =============================================================================

variable "s3_bucket_name" {
  description = "Name of the existing S3 bucket containing exports"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket (defaults to arn:aws:s3:::bucket_name)"
  type        = string
  default     = ""
}

variable "s3_prefix" {
  description = "S3 prefix for exports (include trailing slash)"
  type        = string
  default     = "exports/"
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
# SNOWPIPE OBJECT NAMES
# =============================================================================

variable "landing_table_name" {
  description = "Name of the raw landing table"
  type        = string
  default     = "RAW_EXPORTS"
}

variable "pipe_name" {
  description = "Name of the Snowpipe"
  type        = string
  default     = "PIPE_S3_EXPORTS"
}

variable "stage_name" {
  description = "Name of the external stage"
  type        = string
  default     = "STG_S3_EXPORTS"
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
  default     = 50
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
  default     = "mssql-exports"
}

variable "tags" {
  description = "Additional tags for AWS resources"
  type        = map(string)
  default     = {}
}
