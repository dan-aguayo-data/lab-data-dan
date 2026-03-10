variable "snowflake_organization" {
  description = "Snowflake organization name"
  type        = string
  sensitive   = true
}

variable "snowflake_account_name" {
  description = "Snowflake account name"
  type        = string
  sensitive   = true
}

variable "snowflake_user" {
  description = "Snowflake service user"
  type        = string
  sensitive   = true
}

variable "snowflake_role" {
  description = "Snowflake role"
  type        = string
  sensitive   = true
}

variable "private_key_path" {
  description = "Path to private key (local)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "private_key" {
  description = "Private key content (CI/CD)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "databases" {
  description = "Databases to create"
  type = map(object({
    comment             = string
    data_retention_days = optional(number)
    schemas             = list(string)
  }))
}
