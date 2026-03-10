# ============================================
# Terraform Outputs
# ============================================

output "ecr_repository_url" {
  description = "ECR repository URL for BCP export Docker image"
  value       = aws_ecr_repository.bcp_export.repository_url
}

output "export_bucket_name" {
  description = "S3 bucket name for exports"
  value       = var.export_bucket_name
}

output "export_bucket_arn" {
  description = "S3 bucket ARN for exports"
  value       = local.export_bucket_arn
}

output "step_function_arn" {
  description = "Step Functions state machine ARN"
  value       = aws_sfn_state_machine.data_export.arn
}

output "step_function_url" {
  description = "Step Functions console URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/states/home?region=${var.aws_region}#/statemachines/view/${aws_sfn_state_machine.data_export.arn}"
}

output "us_log_group" {
  description = "CloudWatch log group for US exports"
  value       = aws_cloudwatch_log_group.us_export.name
}

output "au_log_group" {
  description = "CloudWatch log group for AU exports"
  value       = aws_cloudwatch_log_group.au_export.name
}

output "us_secret_arn" {
  description = "Secrets Manager ARN for US credentials"
  value       = aws_secretsmanager_secret.us_credentials.arn
  sensitive   = true
}

output "au_secret_arn" {
  description = "Secrets Manager ARN for AU credentials"
  value       = aws_secretsmanager_secret.au_credentials.arn
  sensitive   = true
}

output "sns_notifications_topic" {
  description = "SNS topic ARN for success notifications"
  value       = aws_sns_topic.notifications.arn
}

output "sns_alerts_topic" {
  description = "SNS topic ARN for failure alerts"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = var.enable_dashboard ? "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.project_name}" : "Dashboard not enabled"
}

output "manual_execution_command" {
  description = "AWS CLI command to manually trigger execution"
  value       = "aws stepfunctions start-execution --state-machine-arn ${aws_sfn_state_machine.data_export.arn} --name manual-$(date +%Y%m%d-%H%M%S)"
}

output "deployment_summary" {
  description = "Deployment summary"
  value = {
    project_name    = var.project_name
    environment     = var.environment
    aws_region      = var.aws_region
    execution_mode  = var.execution_mode
    us_enabled      = var.enable_us_export
    au_enabled      = var.enable_au_export
    schedule        = var.enable_schedule ? var.schedule_expression : "disabled"
    fargate_cpu     = var.fargate_cpu
    fargate_memory  = var.fargate_memory
  }
}

