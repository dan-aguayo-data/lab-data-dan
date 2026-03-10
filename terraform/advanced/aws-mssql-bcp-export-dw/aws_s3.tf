# ============================================
# S3 Bucket for MSSQL Exports
# ============================================

resource "aws_s3_bucket" "exports" {
  count  = var.create_export_bucket ? 1 : 0
  bucket = var.export_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "exports" {
  count  = var.create_export_bucket ? 1 : 0
  bucket = aws_s3_bucket.exports[0].id

  versioning_configuration {
    status = "Suspended"  #do disabled when starting from scratch ..
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "exports" {
  count  = var.create_export_bucket ? 1 : 0
  bucket = aws_s3_bucket.exports[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"   #server side encryption with S3-managed keys
    }
    bucket_key_enabled = true
  }
}

#AES-256 encryption at rest (SSE-S3)
#Bucket keys enabled (reduces KMS API calls & costs)
#Automatic encryption for all new objects


resource "aws_s3_bucket_lifecycle_configuration" "exports" {
  count  = var.create_export_bucket ? 1 : 0
  bucket = aws_s3_bucket.exports[0].id

  rule {
    id     = "delete-old-exports"
    status = "Enabled"

    filter {
      prefix = "${var.export_prefix}"
    }

    expiration {
      days = var.export_retention_days
    }
  }
}

resource "aws_s3_bucket_public_access_block" "exports" {
  count  = var.create_export_bucket ? 1 : 0
  bucket = aws_s3_bucket.exports[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Data source for existing bucket if not creating new one
data "aws_s3_bucket" "exports" {
  count  = var.create_export_bucket ? 0 : 1
  bucket = var.export_bucket_name
}

# Local value for bucket ARN (works whether creating or using existing)
locals {
  export_bucket_arn = var.create_export_bucket ? aws_s3_bucket.exports[0].arn : data.aws_s3_bucket.exports[0].arn
}
