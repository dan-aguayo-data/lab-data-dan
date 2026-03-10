# =============================================================================
# Variables
# =============================================================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "notification_email" {
  description = "Email for success/failure notifications (optional)"
  type        = string
  default     = ""
}



# =============================================================================
# Locals
# =============================================================================

locals {
  name_prefix = "snowflake-key-generator"

  common_tags = {
    Project     = "snowflake-service-keys"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
