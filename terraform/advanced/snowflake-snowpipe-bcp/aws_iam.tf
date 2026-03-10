# =============================================================================
# IAM POLICY FOR SNOWFLAKE S3 ACCESS (covers all buckets)
# =============================================================================

resource "aws_iam_policy" "snowflake_s3_access" {
  name        = "${local.resource_prefix}-snowflake-s3-access"
  description = "Allows Snowflake to access S3 buckets for Snowpipe ingestion"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # Object operations for each bucket
      [
        for key, bucket in var.s3_buckets : {
          Sid    = "AllowObjectOps${replace(title(key), "_", "")}"
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:GetObjectVersion"
          ]
          Resource = "arn:aws:s3:::${bucket.name}/${bucket.prefix}*"
        }
      ],
      # Bucket operations for each bucket
      [
        for key, bucket in var.s3_buckets : {
          Sid    = "AllowBucketOps${replace(title(key), "_", "")}"
          Effect = "Allow"
          Action = [
            "s3:ListBucket",
            "s3:GetBucketLocation"
          ]
          Resource = "arn:aws:s3:::${bucket.name}"
          Condition = {
            StringLike = {
              "s3:prefix" = ["${bucket.prefix}*"]
            }
          }
        }
      ]
    )
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
