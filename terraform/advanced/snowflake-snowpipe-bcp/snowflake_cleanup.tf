# =============================================================================
# DATA RETENTION CLEANUP - STORED PROCEDURE AND TASK
# =============================================================================

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
