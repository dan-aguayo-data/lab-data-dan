variable "aws_region" {
  description = "AWS region for resources"
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
  default     = "sql-export"
}

variable "vpc_id" {
  description = "VPC ID where ECS tasks will run"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "alert_email" {
  description = "Email address for pipeline failure alerts"
  type        = string
}
