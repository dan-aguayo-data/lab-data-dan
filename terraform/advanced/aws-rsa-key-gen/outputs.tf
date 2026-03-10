# =============================================================================
# Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# Secrets
# -----------------------------------------------------------------------------

output "secrets" {
  description = "Created secrets per service account"
  value = {
    for name, _ in var.service_accounts : name => {
      rsa1_private = aws_secretsmanager_secret.rsa1_private[name].name
      rsa1_public  = aws_secretsmanager_secret.rsa1_public[name].name
      rsa2_private = aws_secretsmanager_secret.rsa2_private[name].name
      rsa2_public  = aws_secretsmanager_secret.rsa2_public[name].name
    }
  }
}

output "secret_arns" {
  description = "Secret ARNs"
  value = {
    rsa1_private = { for k, v in aws_secretsmanager_secret.rsa1_private : k => v.arn }
    rsa1_public  = { for k, v in aws_secretsmanager_secret.rsa1_public : k => v.arn }
    rsa2_private = { for k, v in aws_secretsmanager_secret.rsa2_private : k => v.arn }
    rsa2_public  = { for k, v in aws_secretsmanager_secret.rsa2_public : k => v.arn }
  }
}

# -----------------------------------------------------------------------------
# Step Function
# -----------------------------------------------------------------------------

output "step_function_arn" {
  description = "Step Function ARN"
  value       = aws_sfn_state_machine.key_generator.arn
}

output "step_function_console_url" {
  description = "Step Function console URL"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/states/home?region=${data.aws_region.current.name}#/statemachines/view/${aws_sfn_state_machine.key_generator.arn}"
}

# -----------------------------------------------------------------------------
# Usage Instructions
# -----------------------------------------------------------------------------

output "usage" {
  description = "How to generate keys"
  value       = <<-EOT

    ========================================
    HOW TO USE
    ========================================

    1. Open Step Functions Console:
       ${aws_sfn_state_machine.key_generator.arn}

    2. Click "Start execution"

    3. Enter input JSON:
       {"service_account": "svc_dbt", "key_version": "rsa1"}

    4. View result - includes ALTER USER command for Snowflake

    Valid service_account values:
      - svc_dbt
      - svc_fivetran
      - svc_terraform
      - svc_powerbi

    key_version: rsa1 (primary) or rsa2 (rotation)

    ========================================
  EOT
}
