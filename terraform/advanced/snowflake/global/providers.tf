terraform {
  required_version = ">= 1.6.0"
  
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

# AWS provider for Secrets Manager and S3 backend
provider "aws" {
  region = "ap-southeast-2"
}

# Fetch Terraform's private key from Secrets Manager
data "aws_secretsmanager_secret_version" "terraform_private_key" {
  secret_id = "data/dwh/snowflake/svc_terraform_rsa2_private"
}

provider "snowflake" {
  organization_name = var.snowflake_organization
  account_name      = var.snowflake_account_name
  user              = var.snowflake_user
  role              = var.snowflake_role
  authenticator     = "SNOWFLAKE_JWT"
  
  # Use key from AWS Secrets Manager
  private_key = data.aws_secretsmanager_secret_version.terraform_private_key.secret_string

  request_timeout = 600  # 5 minutes instead of default
  
}