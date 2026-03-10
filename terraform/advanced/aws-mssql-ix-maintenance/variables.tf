# =============================================================================
# Variables - Index Maintenance Infrastructure
# =============================================================================

# -----------------------------------------------------------------------------
# Environment & Naming
# -----------------------------------------------------------------------------
variable "environment" {
  description = "Environment name (dev, uat, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "index-maintenance"
}

variable "step_function_name" {
  description = "Custom name for Step Function. Leave empty to use default naming: {project}-{env}-workflow"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# AWS Configuration
# -----------------------------------------------------------------------------
variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS Region to deploy resources (e.g., ap-southeast-2, us-east-1)"
  type        = string
  # No default - must be provided via TF_VAR_aws_region
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------
variable "vpc_id" {
  description = "VPC ID where Lambda will be deployed"
  type        = string
}

variable "lambda_subnet_ids" {
  description = "List of subnet IDs for Lambda function"
  type        = list(string)
}

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------
variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "Name of the target database"
  type        = string
}

variable "include_tables" {
  description = "Comma-separated list of tables to include in maintenance (empty for all tables)"
  type        = string
}

variable "exclude_tables" {
  description = "Comma-separated list of tables to exclude from maintenance"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Execution Configuration
# -----------------------------------------------------------------------------
variable "procedure_timeout_seconds" {
  description = "Timeout for SQL operations in seconds"
  type        = number
  default     = 300
}

variable "lambda_timeout_seconds" {
  description = "Lambda function timeout in seconds (should be greater than procedure_timeout)"
  type        = number
  default     = 360
}

variable "schedule_expression" {
  description = "CloudWatch Events schedule expression (cron or rate)"
  type        = string
  default     = "cron(0 17 * * ? *)"
}

# -----------------------------------------------------------------------------
# Lambda Layer
# -----------------------------------------------------------------------------
variable "lambda_layer_arns" {
  description = "List of Lambda layer ARNs (pymssql layer must be published in the target region)"
  type        = list(string)
}

# -----------------------------------------------------------------------------
# Alerting
# -----------------------------------------------------------------------------
variable "alert_email_addresses" {
  description = "List of email addresses to receive SNS alerts"
  type        = list(string)
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
