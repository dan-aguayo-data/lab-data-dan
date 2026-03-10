# =============================================================================
# SNOWFLAKE OUTPUTS
# =============================================================================

output "storage_integration_name" {
  description = "Name of the Snowflake storage integration"
  value       = snowflake_storage_integration.s3_integration.name
}

output "snowflake_iam_user_arn" {
  description = "Snowflake's IAM user ARN"
  value       = snowflake_storage_integration.s3_integration.storage_aws_iam_user_arn
}

output "snowflake_external_id" {
  description = "Snowflake's external ID"
  value       = snowflake_storage_integration.s3_integration.describe_output[0].storage_aws_external_id[0].value
  sensitive   = true
}

output "landing_table_fqn" {
  description = "Fully qualified name of the landing table"
  value       = "${var.snowflake_database}.${var.snowflake_schema}.${upper(var.landing_table_name)}"
}

output "file_format_name" {
  description = "Name of the file format"
  value       = snowflake_file_format.csv_pipe_delimited.name
}

# =============================================================================
# PER-BUCKET OUTPUTS
# =============================================================================

output "stages" {
  description = "Map of stage names per bucket"
  value = {
    for key, stage in snowflake_stage.s3_exports : key => stage.name
  }
}

output "pipes" {
  description = "Map of pipe names per bucket"
  value = {
    for key, pipe in snowflake_pipe.auto_ingest : key => pipe.name
  }
}

output "pipe_notification_channels" {
  description = "Map of SQS notification channels per bucket"
  value = {
    for key, pipe in snowflake_pipe.auto_ingest : key => pipe.notification_channel
  }
}

# =============================================================================
# AWS OUTPUTS
# =============================================================================

output "iam_role_arn" {
  description = "ARN of the IAM role for Snowflake"
  value       = aws_iam_role.snowflake_access.arn
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.snowflake_access.name
}

# =============================================================================
# CLEANUP OUTPUTS
# =============================================================================

output "cleanup_procedure_name" {
  description = "Name of the cleanup procedure"
  value       = "${var.snowflake_database}.${var.snowflake_schema}.${snowflake_procedure_sql.cleanup_old_exports.name}"
}

output "cleanup_task_name" {
  description = "Name of the cleanup task"
  value       = "${var.snowflake_database}.${var.snowflake_schema}.${snowflake_task.cleanup_task.name}"
}

# =============================================================================
# CONFIGURATION SUMMARY
# =============================================================================

output "configuration_summary" {
  description = "Summary of deployed configuration"
  value = {
    environment         = var.environment
    database            = var.snowflake_database
    schema              = var.snowflake_schema
    table               = upper(var.landing_table_name)
    max_columns         = var.max_columns
    retention_days      = var.cleanup_retention_days
    buckets_configured  = keys(var.s3_buckets)
  }
}

# =============================================================================
# HELPFUL QUERIES
# =============================================================================

output "pipe_status_queries" {
  description = "Queries to check pipe status for each bucket"
  value = {
    for key, pipe in snowflake_pipe.auto_ingest : key =>
    "SELECT SYSTEM$PIPE_STATUS('${var.snowflake_database}.${var.snowflake_schema}.${pipe.name}');"
  }
}

output "refresh_pipe_commands" {
  description = "Commands to manually refresh pipes"
  value = {
    for key, pipe in snowflake_pipe.auto_ingest : key =>
    "ALTER PIPE ${var.snowflake_database}.${var.snowflake_schema}.${pipe.name} REFRESH;"
  }
}

output "sample_data_query" {
  description = "Query to view sample loaded data"
  value       = <<-SQL
    SELECT _LOADED_AT, _SOURCE_BUCKET, _FILENAME, _JOB_ID, _SOURCE_TABLE, _FILE_ROW_NUMBER,
           COL_1, COL_2, COL_3, COL_4, COL_5
    FROM ${var.snowflake_database}.${var.snowflake_schema}.${upper(var.landing_table_name)}
    ORDER BY _LOADED_AT DESC
    LIMIT 100;
  SQL
}

output "cleanup_task_status_query" {
  description = "Query to check task status"
  value       = "SHOW TASKS LIKE '${snowflake_task.cleanup_task.name}' IN SCHEMA ${var.snowflake_database}.${var.snowflake_schema};"
}

output "manual_cleanup_command" {
  description = "Command to manually run cleanup"
  value       = "CALL ${var.snowflake_database}.${var.snowflake_schema}.CLEANUP_OLD_EXPORTS();"
}
