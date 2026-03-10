# ============================================
# Global Variables
# ============================================


variable "aws_region" {
  description = "Primary AWS region for infrastructure deployment"
  type        = string
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "cost_center" {
  description = "Cost center tag for resource tracking"
  type        = string
  default     = "data-engineering"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "mssql-bcp-export"
}

variable "export_retention_days" {
  description = "Number of days to retain export files in S3 before automatic deletion"
  type        = number
  default     = 7
}


# ============================================
# Networking - VPN Access Required
# ============================================

variable "vpc_id" {
  description = "VPC ID where ECS tasks will run (must have VPN connectivity to MSSQL instances)"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks (must have routes to VPN gateway for MSSQL access)"
  type        = list(string)
}

variable "route_table_ids" {
  description = "Route table IDs for S3 Gateway endpoint (optional - will auto-discover if not provided)"
  type        = list(string)
  default     = []
}

# ============================================
# S3 Configuration
# ============================================

variable "export_bucket_name" {
  description = "S3 bucket name for CSV exports (shared for both US and AU)"
  type        = string
}

variable "data_source_name" {
  description = "Data source/team name for S3 path organization (e.g., 'admin_portal', 'customer_api')"
  type        = string
  default     = "mssql_exports"
}

variable "export_prefix" {
  description = "S3 root prefix for all exports (will be followed by data_source/region/database)"
  type        = string
  default     = "exports/"
}

variable "create_export_bucket" {
  description = "Create the export bucket if it doesn't exist (true) or use existing bucket (false)"
  type        = bool
  default     = false
}

# ============================================
# Execution Configuration
# ============================================

variable "schedule_expression" {
  description = "EventBridge cron expression for scheduled execution (UTC timezone)"
  type        = string
  default     = "cron(0 2 * * ? *)" # 2 AM UTC daily
}

variable "enable_schedule" {
  description = "Enable automatic scheduled execution"
  type        = bool
  default     = true
}

# ============================================
# Compute Resources
# ============================================

variable "fargate_cpu" {
  description = "Fargate CPU units (1024 = 1 vCPU)"
  type        = number
  default     = 2048 # 2 vCPUs
}

variable "fargate_memory" {
  description = "Fargate memory in MB"
  type        = number
  default     = 8192 # 8 GB
}

variable "fargate_ephemeral_storage" {
  description = "Ephemeral storage in GB for temporary CSV files"
  type        = number
  default     = 100
}

variable "task_timeout_seconds" {
  description = "Maximum time allowed for each regional task execution"
  type        = number
  default     = 7200 # 2 hours
}

# ============================================
# Monitoring and Alerts
# ============================================

variable "alert_email" {
  description = "Email address for pipeline failure alerts"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 30
}

variable "enable_dashboard" {
  description = "Create CloudWatch dashboard for monitoring"
  type        = bool
  default     = true
}

# ============================================
# Execution Strategy
# ============================================

variable "execution_mode" {
  description = "Step Functions execution mode: 'parallel' (both regions simultaneously) or 'sequential' (US then AU)"
  type        = string
  default     = "parallel"

  validation {
    condition     = contains(["parallel", "sequential"], var.execution_mode)
    error_message = "execution_mode must be either 'parallel' or 'sequential'"
  }
}
