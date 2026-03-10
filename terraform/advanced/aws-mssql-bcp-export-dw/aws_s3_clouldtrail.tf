# ============================================
# CloudTrail for S3 Bucket Monitoring
# ============================================

# CloudTrail log bucket
resource "aws_s3_bucket" "cloudtrail_logs" {
  count  = var.create_export_bucket ? 1 : 0
  bucket = "${var.export_bucket_name}-cloudtrail-logs"
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  count  = var.create_export_bucket ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  count  = var.create_export_bucket ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs[0].arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# CloudTrail for S3 data events
resource "aws_cloudtrail" "s3_data_events" {
  count                         = var.create_export_bucket ? 1 : 0
  name                          = "${var.project_name}-s3-data-events"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs[0].id
  include_global_service_events = false
  is_multi_region_trail         = false

  depends_on = [aws_s3_bucket_policy.cloudtrail_logs]  

  event_selector {
    read_write_type           = "All"
    include_management_events = false

    data_resource {
      type = "AWS::S3::Object"
      values = [
        "${aws_s3_bucket.exports[0].arn}/*"
      ]
    }
  }

  tags = {
    Name = "${var.project_name}-s3-monitoring"
  }
}