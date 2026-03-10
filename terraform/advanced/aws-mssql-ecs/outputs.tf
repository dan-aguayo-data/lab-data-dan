# Terraform Outputs

output "state_machine_arn" {
  description = "Step Functions state machine ARN"
  value       = aws_sfn_state_machine.data_export.arn
}

output "state_machine_console_url" {
  description = "AWS Console URL for Step Functions state machine"
  value       = "https://${var.aws_region}.console.aws.amazon.com/states/home?region=${var.aws_region}#/statemachines/view/${aws_sfn_state_machine.data_export.arn}"
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_task_definition_arn" {
  description = "ECS task definition ARN"
  value       = aws_ecs_task_definition.export.arn
}

output "export_bucket_name" {
  description = "S3 bucket name for CSV exports"
  value       = aws_s3_bucket.exports.id
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name for ECS tasks"
  value       = aws_cloudwatch_log_group.export.name
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = var.enable_dashboard ? "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.project_name}-pipeline" : null
}

output "secrets_manager_secret_arn" {
  description = "Secrets Manager secret ARN for SA password"
  value       = aws_secretsmanager_secret.sa_password.arn
  sensitive   = true
}

output "sns_notifications_topic_arn" {
  description = "SNS topic ARN for success notifications"
  value       = aws_sns_topic.notifications.arn
}

output "sns_alerts_topic_arn" {
  description = "SNS topic ARN for failure alerts"
  value       = aws_sns_topic.alerts.arn
}

output "manual_trigger_command" {
  description = "AWS CLI command to manually trigger the pipeline"
  value       = "aws stepfunctions start-execution --state-machine-arn ${aws_sfn_state_machine.data_export.arn} --input '{}' --region ${var.aws_region}"
}

output "docker_build_commands" {
  description = "Commands to build and push Docker image"
  value = <<-EOT
    # Build the image
    cd docker
    docker build -t sql-export:latest .
    
    # Login to ECR
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.export.repository_url}
    
    # Tag and push
    docker tag sql-export:latest ${aws_ecr_repository.export.repository_url}:latest
    docker push ${aws_ecr_repository.export.repository_url}:latest
  EOT
}

output "set_password_command" {
  description = "AWS CLI command to set SQL Server SA password"
  value       = "aws secretsmanager put-secret-value --secret-id ${aws_secretsmanager_secret.sa_password.arn} --secret-string 'YourStrongPassword123!' --region ${var.aws_region}"
  sensitive   = true
}

output "view_logs_command" {
  description = "AWS CLI command to tail CloudWatch logs"
  value       = "aws logs tail ${aws_cloudwatch_log_group.export.name} --follow --region ${var.aws_region}"
}
