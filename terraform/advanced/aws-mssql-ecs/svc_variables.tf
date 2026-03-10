

variable "export_bucket_name" {
  description = "S3 bucket for CSV exports (staging for Snowflake)"
  type        = string
}

variable "export_prefix" {
  description = "S3 prefix for exported CSV files"
  type        = string
  default     = "exports/"
}

variable "database_name" {
  description = "Name to use when restoring the database"
  type        = string
  default     = "RestoredDB"
}

variable "tables_to_export" {
  description = "Comma-separated list of tables to export (schema.table format). Leave empty to export all tables."
  type        = string
  default     = ""
}

variable "schedule_expression" {
  description = "Cron expression for daily execution (UTC timezone)"
  type        = string
  default     = "cron(0 2 * * ? *)"  # 2 AM UTC daily
}

variable "fargate_cpu" {
  description = "Fargate CPU units (1024 = 1 vCPU)"
  type        = number
  default     = 4096  # 4 vCPUs
}

variable "fargate_memory" {
  description = "Fargate memory in MB"
  type        = number
  default     = 16384  # 16 GB
}

variable "fargate_ephemeral_storage" {
  description = "Ephemeral storage in GB (must be > 2x backup size)"
  type        = number
  default     = 200
}

variable "task_timeout_seconds" {
  description = "Maximum time allowed for task execution"
  type        = number
  default     = 14400  # 4 hours
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period"
  type        = number
  default     = 30
}

variable "enable_dashboard" {
  description = "Create CloudWatch dashboard for monitoring"
  type        = bool
  default     = true
}

variable "backup_bucket_name" {
  description = "S3 bucket containing .bak backup files"
  type        = string
}

variable "create_backup_bucket" {
  description = "Create the backup bucket if it doesn't exist (true) or use existing bucket (false)"
  type        = bool
  default     = false
}

variable "backup_prefix" {
  description = "S3 prefix where .bak files are stored (e.g., 'backups/daily/')"
  type        = string
  default     = "backups/"
}