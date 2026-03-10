# Adding Additional Snowpipes

This guide explains how to add more Snowpipes to ingest data from different S3 locations, reusing the existing storage integration.

## Overview

The current setup creates:
- **1 Storage Integration** - Cross-account auth between Snowflake and AWS (reusable)
- **1 IAM Role** - AWS role for Snowflake to assume (reusable)
- **1 File Format** - CSV parsing configuration (reusable)
- **1 Stage** - Points to specific S3 prefix
- **1 Table** - Landing table for data
- **1 Pipe** - Auto-ingest pipe

To add more pipes, you can **reuse** the storage integration, IAM role, and file format. You only need to create new stages, tables, and pipes.

---

## Option 1: Add to Existing Terraform (Recommended)

### Step 1: Create a new file `snowflake_additional_pipes.tf`

```hcl
# =============================================================================
# ADDITIONAL SNOWPIPE: Archive Data
# =============================================================================

variable "archive_enabled" {
  description = "Enable archive snowpipe"
  type        = bool
  default     = false
}

# Only create these resources if enabled
resource "snowflake_stage" "archive_stage" {
  count = var.archive_enabled ? 1 : 0

  database            = var.snowflake_database
  schema              = "ARCHIVE"  # Different schema
  name                = "STG_S3_ARCHIVE"
  url                 = "s3://${var.s3_bucket_name}/archive/"
  storage_integration = snowflake_storage_integration.s3_integration.name
  file_format         = "FORMAT_NAME = ${var.snowflake_database}.${var.snowflake_schema}.${snowflake_file_format.csv_pipe_delimited.name}"

  comment = "External stage for archived data"
}

resource "snowflake_table" "archive_raw" {
  count = var.archive_enabled ? 1 : 0

  database = var.snowflake_database
  schema   = "ARCHIVE"
  name     = "RAW_ARCHIVE"

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

  # Add your columns...
  dynamic "column" {
    for_each = range(1, 31)  # 30 columns for this table
    content {
      name     = "COL_${column.value}"
      type     = "VARCHAR"
      nullable = true
    }
  }
}

resource "snowflake_pipe" "archive_pipe" {
  count = var.archive_enabled ? 1 : 0

  database    = var.snowflake_database
  schema      = "ARCHIVE"
  name        = "PIPE_ARCHIVE"
  auto_ingest = true

  copy_statement = <<-SQL
    COPY INTO ${var.snowflake_database}.ARCHIVE.RAW_ARCHIVE
    (_FILENAME, _FILE_ROW_NUMBER, ${join(", ", [for i in range(1, 31) : "COL_${i}"])})
    FROM (
      SELECT
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        ${join(", ", [for i in range(1, 31) : format("$%d", i)])}
      FROM @${var.snowflake_database}.ARCHIVE.STG_S3_ARCHIVE
    )
    FILE_FORMAT = (FORMAT_NAME = '${var.snowflake_database}.${var.snowflake_schema}.FF_CSV_PIPE_GZIP')
  SQL

  depends_on = [
    snowflake_table.archive_raw,
    snowflake_stage.archive_stage
  ]
}

# S3 notification for archive pipe
resource "aws_s3_bucket_notification" "archive_trigger" {
  count  = var.archive_enabled ? 1 : 0
  bucket = var.s3_bucket_name

  queue {
    id            = "archive-notifications"
    queue_arn     = snowflake_pipe.archive_pipe[0].notification_channel
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "archive/"
    filter_suffix = ".csv.gz"
  }

  depends_on = [snowflake_pipe.archive_pipe]
}
```

### Step 2: Enable in terraform.tfvars

```hcl
archive_enabled = true
```

### Step 3: Apply

```powershell
terraform plan
terraform apply
```

---

## Option 2: Use Terraform Modules (For Many Pipes)

If you need many pipes with similar patterns, create a reusable module.

### Module Structure

```
modules/
└── snowpipe/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

### modules/snowpipe/variables.tf

```hcl
variable "database" {
  type = string
}

variable "schema" {
  type = string
}

variable "table_name" {
  type = string
}

variable "pipe_name" {
  type = string
}

variable "stage_name" {
  type = string
}

variable "s3_url" {
  type = string
}

variable "s3_prefix" {
  type = string
}

variable "storage_integration_name" {
  type = string
}

variable "file_format_fqn" {
  type = string
}

variable "max_columns" {
  type    = number
  default = 50
}

variable "s3_bucket_name" {
  type = string
}
```

### modules/snowpipe/main.tf

```hcl
resource "snowflake_stage" "stage" {
  database            = var.database
  schema              = var.schema
  name                = var.stage_name
  url                 = var.s3_url
  storage_integration = var.storage_integration_name
  file_format         = "FORMAT_NAME = ${var.file_format_fqn}"
}

resource "snowflake_table" "landing" {
  database = var.database
  schema   = var.schema
  name     = var.table_name

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
  }

  column {
    name     = "_SOURCE_TABLE"
    type     = "VARCHAR"
    nullable = true
  }

  dynamic "column" {
    for_each = range(1, var.max_columns + 1)
    content {
      name     = "COL_${column.value}"
      type     = "VARCHAR"
      nullable = true
    }
  }
}

resource "snowflake_pipe" "pipe" {
  database    = var.database
  schema      = var.schema
  name        = var.pipe_name
  auto_ingest = true

  copy_statement = <<-SQL
    COPY INTO ${var.database}.${var.schema}.${var.table_name}
    (
      _FILENAME, _FILE_ROW_NUMBER, _JOB_ID, _SOURCE_TABLE,
      ${join(", ", [for i in range(1, var.max_columns + 1) : "COL_${i}"])}
    )
    FROM (
      SELECT
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        SPLIT_PART(METADATA$FILENAME, '/', 2),
        REGEXP_REPLACE(SPLIT_PART(METADATA$FILENAME, '/', -1), '\\.csv\\.gz$', ''),
        ${join(", ", [for i in range(1, var.max_columns + 1) : format("$%d", i)])}
      FROM @${var.database}.${var.schema}.${var.stage_name}
    )
    FILE_FORMAT = (FORMAT_NAME = '${var.file_format_fqn}')
  SQL

  depends_on = [snowflake_table.landing, snowflake_stage.stage]
}
```

### modules/snowpipe/outputs.tf

```hcl
output "pipe_notification_channel" {
  value = snowflake_pipe.pipe.notification_channel
}

output "table_fqn" {
  value = "${var.database}.${var.schema}.${var.table_name}"
}
```

### Using the Module

```hcl
# Main exports pipe
module "exports_pipe" {
  source = "./modules/snowpipe"

  database                 = "LANDING"
  schema                   = "SNOWPIPE"
  table_name               = "RAW_EXPORTS"
  pipe_name                = "PIPE_EXPORTS"
  stage_name               = "STG_EXPORTS"
  s3_url                   = "s3://my-bucket/exports/"
  s3_prefix                = "exports/"
  storage_integration_name = snowflake_storage_integration.s3_integration.name
  file_format_fqn          = "${var.snowflake_database}.${var.snowflake_schema}.FF_CSV_PIPE_GZIP"
  max_columns              = 50
  s3_bucket_name           = var.s3_bucket_name
}

# Archive pipe
module "archive_pipe" {
  source = "./modules/snowpipe"

  database                 = "LANDING"
  schema                   = "ARCHIVE"
  table_name               = "RAW_ARCHIVE"
  pipe_name                = "PIPE_ARCHIVE"
  stage_name               = "STG_ARCHIVE"
  s3_url                   = "s3://my-bucket/archive/"
  s3_prefix                = "archive/"
  storage_integration_name = snowflake_storage_integration.s3_integration.name
  file_format_fqn          = "${var.snowflake_database}.${var.snowflake_schema}.FF_CSV_PIPE_GZIP"
  max_columns              = 30
  s3_bucket_name           = var.s3_bucket_name
}
```

---

## Important Notes

### Storage Integration Allowed Locations

If your new pipe uses a different S3 prefix, you need to update the storage integration's `storage_allowed_locations`:

```hcl
resource "snowflake_storage_integration" "s3_integration" {
  # ...
  storage_allowed_locations = [
    "s3://${var.s3_bucket_name}/exports/",
    "s3://${var.s3_bucket_name}/archive/",   # Add new prefix
    "s3://${var.s3_bucket_name}/other/",     # Add more as needed
  ]
}
```

### S3 Bucket Notifications

Each pipe gets its own SQS queue (managed by Snowflake). You can have multiple S3 notifications pointing to different queues with different prefixes/suffixes.

### Schema Separation

Consider organizing pipes by schema:
- `LANDING.EXPORTS` - Main exports
- `LANDING.ARCHIVE` - Archived data
- `LANDING.REALTIME` - Real-time feeds

This makes permissions and organization cleaner.

---

## Quick Checklist for Adding a New Pipe

1. [ ] Decide on S3 prefix (e.g., `archive/`)
2. [ ] Add prefix to storage integration's `storage_allowed_locations`
3. [ ] Create schema if needed
4. [ ] Create stage pointing to new S3 prefix
5. [ ] Create landing table with appropriate column count
6. [ ] Create pipe with COPY statement
7. [ ] Add S3 bucket notification for new prefix
8. [ ] `terraform apply`
9. [ ] Verify with `SELECT SYSTEM$PIPE_STATUS('...')`
10. [ ] Test with sample file upload
