# =============================================================================
# S3 BUCKET NOTIFICATION CONFIGURATION
# =============================================================================

# Snowflake auto-ingest creates its own SQS queue.
# We configure S3 to send notifications to Snowflake's queue.
# The notification_channel is an SQS ARN provided by Snowflake after pipe creation.

resource "aws_s3_bucket_notification" "snowpipe_trigger" {
  bucket = var.s3_bucket_name

  queue {
    id            = "${var.project_name}-${var.environment}-notifications"
    queue_arn     = snowflake_pipe.auto_ingest.notification_channel
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = var.s3_prefix
    filter_suffix = ".csv.gz"
  }

  depends_on = [snowflake_pipe.auto_ingest]
}
