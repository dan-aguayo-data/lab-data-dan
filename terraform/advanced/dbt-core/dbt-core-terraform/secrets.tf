############################################
# SECRETS MANAGER - DATA SOURCE
# References existing secret containing Snowflake private key
############################################

data "aws_secretsmanager_secret" "snowflake_dbt" {
  name = var.snowflake_secret_name
}

data "aws_secretsmanager_secret_version" "snowflake_dbt" {
  secret_id = data.aws_secretsmanager_secret.snowflake_dbt.id
}


data "aws_secretsmanager_secret" "github_token" {
  name = var.dbt_github_token_secret_name
}