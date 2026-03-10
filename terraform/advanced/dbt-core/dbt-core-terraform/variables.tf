############################################
# AWS CONFIGURATION
############################################

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "Environment name (dev, uat, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "dbt-core"
}

############################################
# NETWORKING
############################################

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "172.17.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
  default     = 2
}

############################################
# ECS / FARGATE
############################################

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "fargate-dbt-cluster"
}

variable "fargate_cpu" {
  description = "Fargate CPU units (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256
}

variable "fargate_memory" {
  description = "Fargate memory in MiB"
  type        = number
  default     = 512
}

variable "fargate_platform_version" {
  description = "Fargate platform version"
  type        = string
  default     = "LATEST"
}

variable "cpu_architecture" {
  description = "CPU architecture (X86_64 or ARM64)"
  type        = string
  default     = "ARM64"
}

############################################
# ECR
############################################

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "dbt-repo"
}

variable "ecr_image_tag" {
  description = "Docker image tag to use"
  type        = string
  default     = "latest"
}

############################################
# SECRETS MANAGER
############################################

variable "snowflake_secret_name" {
  description = "Name of the Secrets Manager secret containing Snowflake private key"
  type        = string
  sensitive   = true
}

variable "dbt_github_token_secret_name" {
  description = "Name of the Secrets Manager secret containing GitHub PAT for cloning dbt repo"
  type        = string
  sensitive   = true
}

############################################
# SNOWFLAKE CONFIGURATION (Sensitive - from load-env.ps1)
############################################

variable "snowflake_org_account_name" {
  description = "Snowflake account identifier (e.g., ORG-ACCOUNT)"
  type        = string
  sensitive   = true
}

variable "snowflake_dbt_user" {
  description = "Snowflake service account username"
  type        = string
  sensitive   = true
}

variable "snowflake_dbt_role" {
  description = "Snowflake role for dbt"
  type        = string
  sensitive   = true
}

variable "dbt_target_database" {
  description = "Snowflake database"
  type        = string
  sensitive   = true
}

variable "dbt_default_warehouse" {
  description = "Snowflake warehouse"
  type        = string
  sensitive   = true
}

variable "dbt_email_alerts" {
  description = "Email address for SNS alerts"
  type        = string
  sensitive   = true
}

############################################
# NON-SENSITIVE DBT CONFIG (from terraform.tfvars)
############################################

variable "dbt_schema" {
  description = "Snowflake schema"
  type        = string
}

variable "dbt_target" {
  description = "dbt target environment (dev, uat, prod)"
  type        = string
  default     = "dev"
}

############################################
# S3 ARTIFACTS
############################################

variable "artifacts_bucket_prefix" {
  description = "Prefix for the S3 artifacts bucket name"
  type        = string
  default     = "dbt-artifacts"
}

############################################
# TERRAFORM STATE BACKEND
# Set via: $env:TF_VAR_terraform_state_bucket
#          $env:TF_VAR_terraform_dynamodb_table
############################################

variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
  # No default - must be provided via environment variable
}

variable "terraform_state_key" {
  description = "S3 key path for Terraform state file"
  type        = string
  default     = "ecs_dbt_core/terraform.tfstate"
}

variable "terraform_dynamodb_table" {
  description = "DynamoDB table for Terraform state locking"
  type        = string
  # No default - must be provided via environment variable
}

############################################
# LOGGING
############################################

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
  default     = "/ecs/dbt-task"
}

############################################
# ALERTING
# Set via: $env:TF_VAR_alert_email
############################################

variable "alert_email" {
  description = "Email address for SNS alerts"
  type        = string
  sensitive   = true
  # No default - must be provided via environment variable
}

############################################
# DBT JOBS CONFIGURATION
############################################

variable "dbt_jobs" {
  description = "Map of dbt jobs with their configurations"
  type = map(object({
    description         = string
    dbt_command         = string
    dbt_select          = optional(string)
    dbt_exclude         = optional(string)
    dbt_full_refresh    = optional(bool, false)
    schedule_enabled    = optional(bool, true)
    schedule_expression = string
    timeout_minutes     = optional(number, 60)
  }))
  default = {}
}

############################################
# STEP FUNCTIONS
############################################

variable "enable_step_functions" {
  description = "Enable Step Functions state machine for orchestration"
  type        = bool
  default     = true
}

variable "step_function_retry_attempts" {
  description = "Number of retry attempts for failed tasks"
  type        = number
  default     = 2
}

variable "step_function_retry_interval" {
  description = "Initial retry interval in seconds"
  type        = number
  default     = 60
}
