# ============================================
# AU Database Configuration
# ============================================

variable "au_mssql_host" {
  description = "AU MSSQL server hostname or IP (set via TF_VAR_au_mssql_host in load-env.ps1)"
  type        = string
  sensitive   = true
}

variable "au_mssql_port" {
  description = "AU MSSQL server port"
  type        = number
  default     = 1433
}

variable "au_mssql_user" {
  description = "AU MSSQL database username (set via TF_VAR_au_mssql_user in load-env.ps1)"
  type        = string
  sensitive   = true
}

variable "au_mssql_password" {
  description = "AU MSSQL database password (set via TF_VAR_au_mssql_password in load-env.ps1)"
  type        = string
  sensitive   = true
}

variable "au_database_name" {
  description = "AU MSSQL database name to connect to"
  type        = string
  default     = "EFTSURE_DEV2"
}

variable "au_tables_to_export" {
  description = "Comma-separated list of tables to export from AU database (schema.table format). Leave empty to export all user tables."
  type        = string
  default     = ""
  # Example: "dbo.Orders,dbo.Customers,sales.Invoices"
}

variable "au_bcp_batch_size"  {
  description = "BCP batch size for AU exports (rows per batch)"
  type        = number
}

variable "enable_au_export" {
  description = "Enable AU database export in Step Functions"
  type        = bool
  default     = true
}
