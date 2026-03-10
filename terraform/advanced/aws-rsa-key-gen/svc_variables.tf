variable "service_accounts" {
  description = "Service accounts to create secrets for"
  type = map(object({
    snowflake_user = string
    description    = string
  }))
  default = {
    svc_dbt = {
      snowflake_user = "SVC_DBT"
      description    = "dbt service account"
    }
    svc_fivetran = {
      snowflake_user = "SVC_FIVETRAN"
      description    = "Fivetran service account"
    }
    svc_terraform = {
      snowflake_user = "SVC_TERRAFORM"
      description    = "Terraform service account"
    }
    svc_powerbi = {
      snowflake_user = "SVC_POWERBI"
      description    = "Power BI service account"
    }
  }
}