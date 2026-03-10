terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      CostCenter  = var.cost_center
      ManagedBy   = "Terraform"
      Purpose     = "MSSQL BCP Export Pipeline"
    }
  }
}


# EU provider for GDPR-compliant storage
provider "aws" {
  alias  = "eu"
  region = "eu-west-1"  # Ireland

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      CostCenter  = var.cost_center
      Purpose     = "MSSQL BCP Export Pipeline - EU GDPR"
    }
  }
}