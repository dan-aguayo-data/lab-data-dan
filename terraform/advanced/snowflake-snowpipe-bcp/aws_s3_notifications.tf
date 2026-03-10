# =============================================================================
# S3 BUCKET NOTIFICATIONS (one per bucket)
# =============================================================================
# 
# NOTE ON CROSS-REGION BUCKETS:
# S3 bucket notifications must be configured in the bucket's region.
# If a bucket is in a different region (e.g., eu-west-1), you have two options:
#
# Option 1: Use a separate AWS provider with an alias for that region
#   provider "aws" {
#     alias  = "eu"
#     region = "eu-west-1"
#   }
#   Then reference: provider = aws.eu
#
# Option 2: Configure the notification manually or via a separate Terraform workspace
#
# For now, this assumes all buckets are accessible from the default provider.
# Cross-region S3 -> SQS notifications work fine; you just need permission.
# =============================================================================

resource "aws_s3_bucket_notification" "snowpipe_trigger" {
  for_each = var.s3_buckets

  bucket = each.value.name

  queue {
    id            = "${var.project_name}-${each.key}-notifications"
    queue_arn     = snowflake_pipe.auto_ingest[each.key].notification_channel
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = each.value.prefix
    filter_suffix = ".csv.gz"
  }

  depends_on = [snowflake_pipe.auto_ingest]
}
