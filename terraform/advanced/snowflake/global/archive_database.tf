resource "snowflake_database" "archive_db" {
  name                        = "EFTSURE_ARCHIVE"
  comment                     = "Database for Archived Data"
  data_retention_time_in_days = 1
  
  lifecycle {
    prevent_destroy = true  
  }
}