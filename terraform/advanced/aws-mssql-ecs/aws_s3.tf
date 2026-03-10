# S3 Buckets for backup files and exports

# ============================================
# Backup Bucket (conditional creation)
# ============================================
# If your backup bucket already exists, set create_backup_bucket = false
# If it doesn't exist, set create_backup_bucket = true

resource "aws_s3_bucket" "backups" {
  count = var.create_backup_bucket ? 1 : 0

  bucket = var.backup_bucket_name
}

# Reference to backup bucket (use created one or existing one)
data "aws_s3_bucket" "backups" {
  count = var.create_backup_bucket ? 0 : 1
  
  bucket = var.backup_bucket_name
}

locals {
  backup_bucket_arn = var.create_backup_bucket ? aws_s3_bucket.backups[0].arn : data.aws_s3_bucket.backups[0].arn
  backup_bucket_id  = var.backup_bucket_name
}

# ============================================
# Export Bucket (always created)
# ============================================

resource "aws_s3_bucket" "exports" {
  bucket = var.export_bucket_name
}

resource "aws_s3_bucket_versioning" "exports" {
  bucket = aws_s3_bucket.exports.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "exports" {
  bucket = aws_s3_bucket.exports.id

  rule {
    id     = "delete-old-exports"
    status = "Enabled"

    filter {
      prefix = var.export_prefix
    }

    expiration {
      days = 7  # Keep exports for 7 days (adjust based on needs)
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "exports" {
  bucket = aws_s3_bucket.exports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "exports" {
  bucket = aws_s3_bucket.exports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
