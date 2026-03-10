# =============================================================================
# SNOWFLAKE STORAGE INTEGRATION (shared across all buckets)
# =============================================================================

locals {
  storage_integration_name = var.storage_integration_name != "" ? var.storage_integration_name : upper("${replace(local.resource_prefix, "-", "_")}_S3_INT")
}

resource "snowflake_storage_integration" "s3_integration" {
  name                      = local.storage_integration_name
  type                      = "EXTERNAL_STAGE"
  enabled                   = true
  storage_provider          = "S3"
  storage_allowed_locations = local.storage_allowed_locations

  storage_aws_role_arn = "arn:aws:iam::${var.aws_account_id}:role/${local.resource_prefix}-snowflake-role"

  comment = "Storage integration for ${var.project_name} S3 exports (${var.environment})"
}

# =============================================================================
# SNOWFLAKE FILE FORMAT (shared across all pipes)
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
# SNOWFLAKE LANDING TABLE (shared - all pipes load here)
# =============================================================================

resource "snowflake_table" "raw_exports" {
  database = var.snowflake_database
  schema   = var.snowflake_schema
  name     = upper(var.landing_table_name)

  comment = "Raw landing table for S3 exports. Max columns: ${var.max_columns}"

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

  column {
    name     = "_SOURCE_BUCKET"
    type     = "VARCHAR"
    nullable = true
    comment  = "Source bucket identifier for multi-bucket tracking"
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
# SNOWFLAKE STAGES (one per bucket)
# =============================================================================

resource "snowflake_stage" "s3_exports" {
  for_each = var.s3_buckets

  database            = var.snowflake_database
  schema              = var.snowflake_schema
  name                = upper("STG_${each.key}")
  url                 = "s3://${each.value.name}/${each.value.prefix}"
  storage_integration = snowflake_storage_integration.s3_integration.name
  file_format         = "FORMAT_NAME = ${var.snowflake_database}.${var.snowflake_schema}.${snowflake_file_format.csv_pipe_delimited.name}"

  comment = "External stage for ${each.key} bucket"

  depends_on = [
    snowflake_file_format.csv_pipe_delimited,
    snowflake_storage_integration.s3_integration
  ]
}

# =============================================================================
# SNOWFLAKE PIPES (one per bucket)
# =============================================================================

resource "snowflake_pipe" "auto_ingest" {
  for_each = var.s3_buckets

  database = var.snowflake_database
  schema   = var.snowflake_schema
  name     = upper("PIPE_${each.key}")

  auto_ingest = true

  comment = "Auto-ingest pipe for ${each.key} bucket"

  copy_statement = <<-SQL
    COPY INTO ${var.snowflake_database}.${var.snowflake_schema}.${upper(var.landing_table_name)}
    (
      _FILENAME,
      _FILE_ROW_NUMBER,
      _JOB_ID,
      _SOURCE_TABLE,
      _SOURCE_BUCKET,
      ${join(", ", [for i in range(1, var.max_columns + 1) : "COL_${i}"])}
    )
    FROM (
      SELECT
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        SPLIT_PART(METADATA$FILENAME, '/', 2),
        REGEXP_REPLACE(SPLIT_PART(METADATA$FILENAME, '/', -1), '\\.csv\\.gz$', ''),
        '${each.key}',
        ${join(", ", [for i in range(1, var.max_columns + 1) : format("$%d", i)])}
      FROM @${var.snowflake_database}.${var.snowflake_schema}.${upper("STG_${each.key}")}
    )
    FILE_FORMAT = (FORMAT_NAME = '${var.snowflake_database}.${var.snowflake_schema}.${upper(var.file_format_name)}')
  SQL

  depends_on = [
    snowflake_table.raw_exports,
    snowflake_stage.s3_exports,
    snowflake_file_format.csv_pipe_delimited
  ]
}
