# =============================================================================
# SNOWFLAKE STORAGE INTEGRATION
# =============================================================================

resource "snowflake_storage_integration" "s3_integration" {
  name                      = local.storage_integration_name
  type                      = "EXTERNAL_STAGE"
  enabled                   = true
  storage_provider          = "S3"
  storage_allowed_locations = local.storage_allowed_locations

  # The AWS role ARN
  storage_aws_role_arn = "arn:aws:iam::${var.aws_account_id}:role/${local.resource_prefix}-snowflake-role"

  comment = "Storage integration for ${var.project_name} S3 exports (${var.environment})"
}

# =============================================================================
# SNOWFLAKE FILE FORMAT
# =============================================================================

resource "snowflake_file_format" "csv_pipe_delimited" {
  database = var.snowflake_database
  schema   = var.snowflake_schema
  name     = upper(var.file_format_name)

  format_type = "CSV"

  compression                    = "GZIP"
  field_delimiter                = var.field_delimiter
  skip_header                    = var.skip_header
  null_if                        = var.null_if
  empty_field_as_null            = true
  encoding                       = "UTF8"
  error_on_column_count_mismatch = false

  comment = "CSV file format: pipe-delimited, gzip compressed"
}

# =============================================================================
# SNOWFLAKE EXTERNAL STAGE
# =============================================================================

resource "snowflake_stage" "s3_exports" {
  database            = var.snowflake_database
  schema              = var.snowflake_schema
  name                = upper(var.stage_name)
  url                 = "s3://${var.s3_bucket_name}/${var.s3_prefix}"
  storage_integration = snowflake_storage_integration.s3_integration.name
  file_format         = "FORMAT_NAME = ${var.snowflake_database}.${var.snowflake_schema}.${snowflake_file_format.csv_pipe_delimited.name}"

  comment = "External stage for S3 exports"

  depends_on = [
    snowflake_file_format.csv_pipe_delimited,
    snowflake_storage_integration.s3_integration
  ]
}

# =============================================================================
# SNOWFLAKE LANDING TABLE
# =============================================================================

resource "snowflake_table" "raw_exports" {
  database = var.snowflake_database
  schema   = var.snowflake_schema
  name     = upper(var.landing_table_name)

  comment = "Raw landing table for S3 exports. Metadata columns prefixed with underscore. Max columns: ${var.max_columns}"

  # Metadata columns
  column {
    name     = "_LOADED_AT"
    type     = "TIMESTAMP_NTZ"
    nullable = false
    default {
      expression = "CURRENT_TIMESTAMP()"
    }
  }

  column {
    name     = "_FILENAME"
    type     = "VARCHAR"
    nullable = true
  }

  column {
    name     = "_FILE_ROW_NUMBER"
    type     = "NUMBER"
    nullable = true
  }

  column {
    name     = "_JOB_ID"
    type     = "VARCHAR"
    nullable = true
    comment  = "Extracted from file path: {prefix}/{JOB_ID}/table.csv.gz"
  }

  column {
    name     = "_SOURCE_TABLE"
    type     = "VARCHAR"
    nullable = true
    comment  = "Extracted from filename: {schema}_{table}.csv.gz"
  }

  # Dynamic data columns (COL_1 through COL_N)
  dynamic "column" {
    for_each = range(1, var.max_columns + 1)
    content {
      name     = "COL_${column.value}"
      type     = "VARCHAR"
      nullable = true
    }
  }
}

# =============================================================================
# SNOWFLAKE PIPE
# =============================================================================

resource "snowflake_pipe" "auto_ingest" {
  database = var.snowflake_database
  schema   = var.snowflake_schema
  name     = upper(var.pipe_name)

  auto_ingest = true

  comment = "Auto-ingest pipe for S3 CSV exports"

  # COPY statement with metadata extraction
  copy_statement = <<-SQL
    COPY INTO ${var.snowflake_database}.${var.snowflake_schema}.${upper(var.landing_table_name)}
    (
      _FILENAME,
      _FILE_ROW_NUMBER,
      _JOB_ID,
      _SOURCE_TABLE,
      ${join(", ", [for i in range(1, var.max_columns + 1) : "COL_${i}"])}
    )
    FROM (
      SELECT
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        -- Extract JOB_ID from path: {prefix}/{JOB_ID}/filename.csv.gz
        SPLIT_PART(METADATA$FILENAME, '/', 2),
        -- Extract source table from filename (remove .csv.gz extension)
        REGEXP_REPLACE(SPLIT_PART(METADATA$FILENAME, '/', -1), '\\.csv\\.gz$', ''),
        ${join(", ", [for i in range(1, var.max_columns + 1) : format("$%d", i)])}
      FROM @${var.snowflake_database}.${var.snowflake_schema}.${upper(var.stage_name)}
    )
    FILE_FORMAT = (FORMAT_NAME = '${var.snowflake_database}.${var.snowflake_schema}.${upper(var.file_format_name)}')
  SQL

  depends_on = [
    snowflake_table.raw_exports,
    snowflake_stage.s3_exports,
    snowflake_file_format.csv_pipe_delimited
  ]
}
