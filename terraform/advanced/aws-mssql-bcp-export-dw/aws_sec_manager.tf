# ============================================
# Secrets Manager - US Database Credentials
# ============================================

resource "aws_secretsmanager_secret" "us_credentials" {
  name                    = "${var.project_name}/us/credentials"
  description             = "US MSSQL database credentials for BCP export"
  recovery_window_in_days = 7

  tags = {
    Region   = "US"
    Database = var.us_database_name
  }
}

resource "aws_secretsmanager_secret_version" "us_credentials" {
  secret_id = aws_secretsmanager_secret.us_credentials.id
  secret_string = jsonencode({
    host     = var.us_mssql_host
    port     = var.us_mssql_port
    username = var.us_mssql_user
    password = var.us_mssql_password
    database = var.us_database_name
  })
}

# ============================================
# Secrets Manager - AU Database Credentials
# ============================================

resource "aws_secretsmanager_secret" "au_credentials" {
  name                    = "${var.project_name}/au/credentials"
  description             = "AU MSSQL database credentials for BCP export"
  recovery_window_in_days = 7

  tags = {
    Region   = "AU"
    Database = var.au_database_name
  }
}

resource "aws_secretsmanager_secret_version" "au_credentials" {
  secret_id = aws_secretsmanager_secret.au_credentials.id
  secret_string = jsonencode({
    host     = var.au_mssql_host
    port     = var.au_mssql_port
    username = var.au_mssql_user
    password = var.au_mssql_password
    database = var.au_database_name
  })
}
