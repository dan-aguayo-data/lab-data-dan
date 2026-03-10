# Secrets Manager for SQL Server SA password

resource "aws_secretsmanager_secret" "sa_password" {
  name        = "${var.project_name}/sa-password"
  description = "SQL Server SA password for ${var.project_name}"

  recovery_window_in_days = 7
}

# Note: Secret value must be set manually after terraform apply
# aws secretsmanager put-secret-value \
#   --secret-id <secret-arn> \
#   --secret-string "YourStrongPassword123!"

# Password rotation not needed for a 3-month temporary project
# For production long-term use, consider enabling automatic rotation