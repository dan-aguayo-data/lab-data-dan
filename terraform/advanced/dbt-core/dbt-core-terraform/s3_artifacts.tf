############################################
# S3 BUCKET FOR DBT ARTIFACTS
############################################

resource "aws_s3_bucket" "dbt_artifacts" {
  bucket = "${var.artifacts_bucket_prefix}-${random_string.suffix.result}"

  tags = {
    Name = "${var.artifacts_bucket_prefix}-${random_string.suffix.result}"
  }
}

############################################
# VERSIONING
############################################

resource "aws_s3_bucket_versioning" "dbt_artifacts" {
  bucket = aws_s3_bucket.dbt_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

############################################
# ENCRYPTION
############################################

resource "aws_s3_bucket_server_side_encryption_configuration" "dbt_artifacts" {
  bucket = aws_s3_bucket.dbt_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

############################################
# PUBLIC ACCESS BLOCK
############################################

resource "aws_s3_bucket_public_access_block" "dbt_artifacts" {
  bucket = aws_s3_bucket.dbt_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

############################################
# LIFECYCLE RULES
# Clean up old artifacts to manage costs
############################################

resource "aws_s3_bucket_lifecycle_configuration" "dbt_artifacts" {
  bucket = aws_s3_bucket.dbt_artifacts.id

  rule {
    id     = "cleanup-old-artifacts"
    status = "Enabled"

    filter {
      prefix = ""
    }

    # Move to cheaper storage after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Delete after 90 days
    expiration {
      days = 90
    }

    # Clean up old versions
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
