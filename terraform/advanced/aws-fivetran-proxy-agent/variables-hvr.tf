# variables-hvr.tf
# Variables for Fivetran Proxy Agent (HVR) Infrastructure
#
# IMPORTANT: Most variables have NO defaults and must be provided via:
#   - GitHub Environment Variables (for GitHub Actions deployments)
#   - load-env.ps1 / load-env.sh (for local deployments)
#
# This allows the same code to deploy to multiple regions (AU, US, etc.)
# without hardcoding region-specific values.

variable "aws_region" {
  description = "AWS region for deployment (e.g., ap-southeast-2 or us-east-1)"
  type        = string
  # No default - must be provided via GitHub environment variable or load-env.ps1
}

# ============================================================================
# Existing Infrastructure (use your existing VPC/subnet)
# ============================================================================

variable "vpc_id" {
  description = "ID of existing VPC where MSSQL is running"
  type        = string
  
  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "VPC ID must start with 'vpc-'"
  }
}

variable "subnet_id" {
  description = "ID of existing private subnet (where MSSQL is)"
  type        = string
  
  validation {
    condition     = can(regex("^subnet-", var.subnet_id))
    error_message = "Subnet ID must start with 'subnet-'"
  }
}

# ============================================================================
# MSSQL Connection
# ============================================================================

variable "mssql_host" {
  description = "IP address or hostname of MSSQL server (e.g., RDS endpoint or private IP)"
  type        = string
  # No default - must be provided via GitHub environment variable or load-env.ps1
}

variable "mssql_port" {
  description = "MSSQL server port"
  type        = number
  default     = 1433
}

variable "instance_type" {
  description = "EC2 instance type for Proxy Agent"
  type        = string
  default     = "t3.medium"
  
  validation {
    condition     = can(regex("^(t3|m5|m6i)\\.(medium|large|xlarge|2xlarge)$", var.instance_type))
    error_message = "Instance type must be t3, m5, or m6i family, medium or larger"
  }
}

variable "hvr_version" {
  description = "HVR version to install (must be 6.1.0_79 or later)"
  type        = string
  default     = "6.1.0_94"
  
  validation {
    condition     = can(regex("^6\\.1\\.0_[7-9][0-9]|^6\\.1\\.0_[1-9][0-9][0-9]", var.hvr_version))
    error_message = "HVR version must be 6.1.0_79 or later"
  }
}

variable "hvr_download_url" {
  description = "Download URL for HVR agent from Fivetran dashboard (copy 'Linux x86' download link)"
  type        = string
  
  validation {
    condition     = can(regex("^https://", var.hvr_download_url))
    error_message = "Download URL must start with https://"
  }
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
  # Tags should be set per environment in GitHub environment variables or load-env.ps1
  # Example:
  # {
  #   Project     = "Fivetran"
  #   Component   = "ProxyAgent"
  #   Environment = "au-production" or "us-production"
  #   ManagedBy   = "Terraform"
  #   Region      = "ap-southeast-2" or "us-east-1"
  # }
}

variable "fivetran_config" {
  description = "Fivetran proxy agent configuration JSON from Fivetran dashboard"
  type        = string
  sensitive   = true
  
  validation {
    condition     = can(jsondecode(var.fivetran_config))
    error_message = "fivetran_config must be valid JSON"
  }
}
