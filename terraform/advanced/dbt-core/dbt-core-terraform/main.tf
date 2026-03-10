############################################
# TERRAFORM CONFIGURATION
############################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Backend configuration
  # NOTE: Backend config cannot use variables - these must be hardcoded
  # or passed via -backend-config CLI flags
  # 
  # To use variables, run:
  # terraform init \
  #   -backend-config="bucket=your-bucket" \
  #   -backend-config="key=your-key" \
  #   -backend-config="dynamodb_table=your-table"
  backend "s3" {
    bucket         = "eft-data-terraform-backend"
    key            = "ecs_dbt_core/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-lock-data-dbt-core"
    encrypt        = true
  }
}

############################################
# PROVIDER
############################################

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

############################################
# DATA SOURCES
############################################

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

############################################
# LOCALS
############################################

locals {
  account_id = data.aws_caller_identity.current.account_id

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # Build ECR image URL dynamically
  ecr_image_url = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repository_name}:${var.ecr_image_tag}"

  # Resource naming convention
  name_prefix = "${var.project_name}-${var.environment}"
}

############################################
# RANDOM SUFFIX FOR UNIQUE NAMES
############################################

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
