# =================
# PROD ENVIRONMENT
# =================
# References global resources and creates prod-specific databases
# NOTE: protect_databases = true prevents accidental deletion

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
  environment         = "prod"
  data_retention_days = 30
  protect_databases   = true  # PROD databases cannot be destroyed via Terraform
  
  # From global state (via remote state)
  dbt_role_name            = data.terraform_remote_state.global.outputs.dbt_role_name
  fivetran_role_name       = data.terraform_remote_state.global.outputs.fivetran_role_name
  powerbi_role_name        = data.terraform_remote_state.global.outputs.powerbi_role_name
  analytics_warehouse_name = data.terraform_remote_state.global.outputs.analytics_warehouse_name
  
  # From terraform.tfvars
  databases = var.databases
}
