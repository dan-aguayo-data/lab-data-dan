# =================
# UAT ENVIRONMENT
# =================
# References global resources and creates uat-specific databases

data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket = "eft-data-terraform-backend"
    key    = "snowflake/global.tfstate"
    region = "ap-southeast-2"
  }
}

module "environment" {
  source = "../../modules/snowflake_environment"
  
  # Environment configuration
  environment         = "uat"
  data_retention_days = 14
  protect_databases   = false
  
  # From global state (via remote state)
  dbt_role_name            = data.terraform_remote_state.global.outputs.dbt_role_name
  fivetran_role_name       = data.terraform_remote_state.global.outputs.fivetran_role_name
  powerbi_role_name        = data.terraform_remote_state.global.outputs.powerbi_role_name
  analytics_warehouse_name = data.terraform_remote_state.global.outputs.analytics_warehouse_name
  
  # From terraform.tfvars
  databases = var.databases
}
