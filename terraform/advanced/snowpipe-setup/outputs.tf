# =============================================================================
# SNOWFLAKE OUTPUTS
# =============================================================================

output "storage_integration_name" {
  description = "Name of the Snowflake storage integration"
  value       = snowflake_storage_integration.s3_integration.name
}

output "snowflake_iam_user_arn" {
  description = "Snowflake's IAM user ARN (for reference)"
  value       = snowflake_storage_integration.s3_integration.storage_aws_iam_user_arn
}

output "snowflake_external_id" {
  description = "Snowflake's external ID (for reference)"
  value       = snowflake_storage_integration.s3_integration.describe_output[0].storage_aws_external_id[0].value
  sensitive   = true
}

output "stage_name" {
  description = "Name of the external stage"
  value       = snowflake_stage.s3_exports.name
}

output "stage_url" {
  description = "Stage URL"
  value       = "s3://${var.s3_bucket_name}/${var.s3_prefix}"
}

output "pipe_name" {
  description = "Name of the Snowpipe"
  value       = snowflake_pipe.auto_ingest.name
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

output "snowpipe_notification_channel" {
  description = "Snowflake's SQS queue ARN for S3 event notifications"
  value       = snowflake_pipe.auto_ingest.notification_channel
}

# =============================================================================
# CONFIGURATION SUMMARY
# =============================================================================

output "configuration_summary" {
  description = "Summary of deployed configuration"
  value = {
    environment      = var.environment
    database         = var.snowflake_database
    schema           = var.snowflake_schema
    table            = upper(var.landing_table_name)
    pipe             = upper(var.pipe_name)
    stage            = upper(var.stage_name)
    max_columns      = var.max_columns
    s3_bucket        = var.s3_bucket_name
    s3_prefix        = var.s3_prefix
    field_delimiter  = var.field_delimiter
  }
}

# =============================================================================
# HELPFUL QUERIES
# =============================================================================

output "pipe_status_query" {
  description = "Query to check pipe status"
  value       = "SELECT SYSTEM$PIPE_STATUS('${var.snowflake_database}.${var.snowflake_schema}.${upper(var.pipe_name)}');"
}

output "copy_history_query" {
  description = "Query to check recent copy history"
  value       = <<-SQL
    SELECT *
    FROM TABLE(${var.snowflake_database}.INFORMATION_SCHEMA.COPY_HISTORY(
      TABLE_NAME => '${var.snowflake_schema}.${upper(var.landing_table_name)}',
      START_TIME => DATEADD(HOUR, -24, CURRENT_TIMESTAMP())
    ))
    ORDER BY LAST_LOAD_TIME DESC;
  SQL
}

output "sample_data_query" {
  description = "Query to view sample loaded data"
  value       = <<-SQL
    SELECT _LOADED_AT, _FILENAME, _JOB_ID, _SOURCE_TABLE, _FILE_ROW_NUMBER,
           COL_1, COL_2, COL_3, COL_4, COL_5
    FROM ${var.snowflake_database}.${var.snowflake_schema}.${upper(var.landing_table_name)}
    ORDER BY _LOADED_AT DESC
    LIMIT 100;
  SQL
}

output "refresh_pipe_command" {
  description = "Command to manually refresh pipe"
  value       = "ALTER PIPE ${var.snowflake_database}.${var.snowflake_schema}.${upper(var.pipe_name)} REFRESH;"
}
