terraform {
  backend "s3" {
    # Values provided via command line or GitHub Actions
    # bucket = "eft-data-terraform-backend"
    # key    = "fivetran_proxy_agent/{environment}/terraform.tfstate"
    # region = "ap-southeast-2" or "us-east-1"
    encrypt = true  # Only static values here
  }
  
  required_version = ">= 1.6.0"
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
    tags = merge(
      {
        ManagedBy  = "Terraform"
        Project    = "Fivetran"
        Component  = "ProxyAgent"
      },
      var.tags
    )
  }
}
