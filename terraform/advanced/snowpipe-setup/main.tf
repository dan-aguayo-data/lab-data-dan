# =============================================================================
# TERRAFORM CONFIGURATION WITH S3 BACKEND
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  # S3 Backend with DynamoDB locking
  backend "s3" {
    bucket         = "eft-data-terraform-backend"
    key            = "snowpipe/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-lock-data-snowpipe"
    encrypt        = true
  }

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# =============================================================================
# LOCALS
# =============================================================================

locals {
  # Resource naming
  resource_prefix = "${var.project_name}-${var.environment}"

  # S3 ARN (use provided or construct from bucket name)
  s3_bucket_arn = var.s3_bucket_arn != "" ? var.s3_bucket_arn : "arn:aws:s3:::${var.s3_bucket_name}"

  # Snowflake storage integration URL
  storage_allowed_locations = ["s3://${var.s3_bucket_name}/${var.s3_prefix}"]

  # Storage integration name (auto-generate if not provided)
  storage_integration_name = var.storage_integration_name != "" ? var.storage_integration_name : upper("${replace(local.resource_prefix, "-", "_")}_S3_INT")

  # Common tags
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# =============================================================================
# AWS PROVIDER
# =============================================================================

provider "aws" {
  region = var.aws_region
}

# =============================================================================
# SNOWFLAKE PROVIDER (using key pair auth from Secrets Manager)
# =============================================================================

data "aws_secretsmanager_secret_version" "terraform_private_key" {
  secret_id = "data/dwh/snowflake/svc_terraform_rsa2_private"
}

provider "snowflake" {
  organization_name = var.snowflake_organization
  account_name      = var.snowflake_account_name
  user              = var.snowflake_user
  role              = var.snowflake_role
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = data.aws_secretsmanager_secret_version.terraform_private_key.secret_string
  request_timeout   = 600

  # Enable preview features required for these resources
  preview_features_enabled = [
    "snowflake_storage_integration_resource",
    "snowflake_file_format_resource",
    "snowflake_table_resource",
    "snowflake_stage_resource",
    "snowflake_pipe_resource",
    "snowflake_procedure_sql_resource"
  ]
}
