# =============================================================================
# IAM POLICY FOR SNOWFLAKE S3 ACCESS
# =============================================================================

resource "aws_iam_policy" "snowflake_s3_access" {
  name        = "${local.resource_prefix}-snowflake-s3-access"
  description = "Allows Snowflake to access S3 bucket for Snowpipe ingestion"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowObjectOperations"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion"
        ]
        Resource = "${local.s3_bucket_arn}/${var.s3_prefix}*"
      },
      {
        Sid    = "AllowBucketOperations"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = local.s3_bucket_arn
        Condition = {
          StringLike = {
            "s3:prefix" = ["${var.s3_prefix}*"]
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

# =============================================================================
# IAM ROLE FOR SNOWFLAKE
# =============================================================================

resource "aws_iam_role" "snowflake_access" {
  name        = "${local.resource_prefix}-snowflake-role"
  description = "Role assumed by Snowflake for S3 access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SnowflakeAccess"
        Effect = "Allow"
        Principal = {
          AWS = snowflake_storage_integration.s3_integration.storage_aws_iam_user_arn
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = snowflake_storage_integration.s3_integration.describe_output[0].storage_aws_external_id[0].value
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach S3 policy to role
resource "aws_iam_role_policy_attachment" "snowflake_s3" {
  role       = aws_iam_role.snowflake_access.name
  policy_arn = aws_iam_policy.snowflake_s3_access.arn
}
