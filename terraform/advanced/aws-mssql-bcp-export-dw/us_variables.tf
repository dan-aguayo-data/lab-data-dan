# ============================================
# US Database Configuration
# ============================================

variable "us_mssql_host" {
  description = "US MSSQL server hostname or IP (set via TF_VAR_us_mssql_host in load-env.ps1)"
  type        = string
  sensitive   = true
}

variable "us_mssql_port" {
  description = "US MSSQL server port"
  type        = number
  default     = 1433
}

variable "us_mssql_user" {
  description = "US MSSQL database username (set via TF_VAR_us_mssql_user in load-env.ps1)"
  type        = string
  sensitive   = true
}

variable "us_mssql_password" {
  description = "US MSSQL database password (set via TF_VAR_us_mssql_password in load-env.ps1)"
  type        = string
  sensitive   = true
}

variable "us_database_name" {
  description = "US MSSQL database name to connect to"
  type        = string
  default     = "EFTSURE_DEV2"
}

variable "us_tables_to_export" {
  description = "Comma-separated list of tables to export from US database (schema.table format). Leave empty to export all user tables."
  type        = string
  default     = ""
  # Example: "dbo.Orders,dbo.Customers,sales.Invoices"
}

variable "us_bcp_batch_size" {
  description = "BCP batch size for US exports (rows per batch)"
  type        = number
}

variable "enable_us_export" {
  description = "Enable US database export in Step Functions"
  type        = bool
  default     = true
}
