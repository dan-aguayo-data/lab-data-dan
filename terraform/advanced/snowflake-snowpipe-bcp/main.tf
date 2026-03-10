# =============================================================================
# TERRAFORM CONFIGURATION WITH S3 BACKEND
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket         = "eft-data-terraform-backend"
    key            = "snowpipe-bcp/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-lock-data-bcp-snowpipe"
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
  resource_prefix = "${var.project_name}-${var.environment}"

  # Build list of all S3 locations for storage integration
  storage_allowed_locations = [
    for key, bucket in var.s3_buckets : "s3://${bucket.name}/${bucket.prefix}"
  ]

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
# SNOWFLAKE PROVIDER
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

  preview_features_enabled = [
    "snowflake_storage_integration_resource",
    "snowflake_file_format_resource",
    "snowflake_table_resource",
    "snowflake_stage_resource",
    "snowflake_pipe_resource",
    "snowflake_procedure_sql_resource"
  ]
}
