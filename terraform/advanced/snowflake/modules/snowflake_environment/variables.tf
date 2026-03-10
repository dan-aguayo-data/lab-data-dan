variable "environment" {
  description = "Environment name (dev, uat, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "Environment must be dev, uat, or prod"
  }
}

variable "data_retention_days" {
  description = "Default data retention days for databases"
  type        = number
}

variable "protect_databases" {
  description = "Enable lifecycle prevent_destroy on databases"
  type        = bool
}

# =================
# GLOBAL REFERENCES (from remote state)
# =================

variable "dbt_role_name" {
  description = "DBT role name from global state"
  type        = string
}

variable "fivetran_role_name" {
  description = "Fivetran role name from global state"
  type        = string
}

variable "powerbi_role_name" {
  description = "PowerBI role name from global state"
  type        = string
}

variable "analytics_warehouse_name" {
  description = "Analytics warehouse name from global state"
  type        = string
}


variable "masking_policy_names" {
  description = "Fully qualified names of masking policies to grant dbt APPLY on"
  type = map(string)
  default = {}
}

# =================
# ENVIRONMENT-SPECIFIC CONFIG
# =================

variable "databases" {
  description = "Map of databases to create"
  type = map(object({
    comment             = string
    data_retention_days = optional(number)
    schemas             = list(string)
  }))
}

variable "legacy_databases" {
  description = "List of existing legacy databases to grant access to"
  type        = list(string)
  default     = ["FIVETRAN", "CUSTOMER_SUCCESS", "CUSTOMER_SUPPORT", "REVENUE_OPERATIONS"]
}
