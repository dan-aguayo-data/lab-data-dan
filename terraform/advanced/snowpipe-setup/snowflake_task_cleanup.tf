# =============================================================================
# DATA RETENTION CLEANUP - STORED PROCEDURE AND TASK
# =============================================================================

# -----------------------------------------------------------------------------
# Variables for cleanup configuration
# -----------------------------------------------------------------------------

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
  description = "Warehouse for cleanup task (tasks require a warehouse)"
  type        = string
}

variable "cleanup_cron_schedule" {
  description = "Cron schedule for cleanup task (without 'USING CRON' prefix)"
  type        = string
  default     = "0 2 * * * UTC"  # Daily at 2 AM UTC
}

# -----------------------------------------------------------------------------
# Stored Procedure
# -----------------------------------------------------------------------------

resource "snowflake_procedure_sql" "cleanup_old_exports" {
  database = var.snowflake_database
  schema   = var.snowflake_schema
  name     = "CLEANUP_OLD_EXPORTS"

  return_type         = "VARCHAR(16777216)"
  execute_as          = "CALLER"
  null_input_behavior = "CALLED ON NULL INPUT"

  procedure_definition = <<-SQL
    BEGIN
      DELETE FROM ${var.snowflake_database}.${var.snowflake_schema}.${upper(var.landing_table_name)}
      WHERE _LOADED_AT < DATEADD(DAY, -${var.cleanup_retention_days}, CURRENT_TIMESTAMP());
      RETURN 'Deleted records older than ${var.cleanup_retention_days} days';
    END
  SQL

  comment = "Cleanup procedure to delete records older than ${var.cleanup_retention_days} days"

  depends_on = [snowflake_table.raw_exports]
}

# -----------------------------------------------------------------------------
# Task
# -----------------------------------------------------------------------------

resource "snowflake_task" "cleanup_task" {
  database  = var.snowflake_database
  schema    = var.snowflake_schema
  name      = "TASK_CLEANUP_OLD_EXPORTS"
  warehouse = var.cleanup_warehouse
  started   = var.cleanup_enabled

  schedule {
    using_cron = var.cleanup_cron_schedule
  }

  sql_statement = "CALL ${var.snowflake_database}.${var.snowflake_schema}.CLEANUP_OLD_EXPORTS()"

  comment = "Daily cleanup of ${upper(var.landing_table_name)} records older than ${var.cleanup_retention_days} days"

  depends_on = [snowflake_procedure_sql.cleanup_old_exports]
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "cleanup_procedure_name" {
  description = "Name of the cleanup procedure"
  value       = "${var.snowflake_database}.${var.snowflake_schema}.${snowflake_procedure_sql.cleanup_old_exports.name}"
}

output "cleanup_task_name" {
  description = "Name of the cleanup task"
  value       = "${var.snowflake_database}.${var.snowflake_schema}.${snowflake_task.cleanup_task.name}"
}

output "cleanup_task_status_query" {
  description = "Query to check task status"
  value       = "SHOW TASKS LIKE '${snowflake_task.cleanup_task.name}' IN SCHEMA ${var.snowflake_database}.${var.snowflake_schema};"
}

output "cleanup_task_history_query" {
  description = "Query to check task run history"
  value       = <<-SQL
    SELECT *
    FROM TABLE(${var.snowflake_database}.INFORMATION_SCHEMA.TASK_HISTORY(
      TASK_NAME => '${snowflake_task.cleanup_task.name}',
      SCHEDULED_TIME_RANGE_START => DATEADD(DAY, -7, CURRENT_TIMESTAMP())
    ))
    ORDER BY SCHEDULED_TIME DESC;
  SQL
}

output "manual_cleanup_command" {
  description = "Command to manually run cleanup"
  value       = "CALL ${var.snowflake_database}.${var.snowflake_schema}.CLEANUP_OLD_EXPORTS();"
}
