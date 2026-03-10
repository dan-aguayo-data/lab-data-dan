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
  description = "Snowflake service user for Terraform"
  type        = string
  sensitive   = true
}

variable "snowflake_role" {
  description = "Snowflake role for Terraform operations"
  type        = string
  sensitive   = true
}

variable "private_key_path" {
  description = "Path to private key file (for local development)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "private_key" {
  description = "Private key content (for CI/CD)"
  type        = string
  default     = ""
  sensitive   = true
}
