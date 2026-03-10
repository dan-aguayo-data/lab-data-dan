############################################
# CLUSTER & TASKS
############################################

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_task_definition_arn" {
  description = "ARN of the dbt task definition"
  value       = aws_ecs_task_definition.dbt.arn
}

############################################
# ECR
############################################

output "ecr_repository_url" {
  description = "URL of the ECR repository for dbt images"
  value       = aws_ecr_repository.dbt.repository_url
}

output "ecr_image_url" {
  description = "Full image URL including tag"
  value       = local.ecr_image_url
}

############################################
# S3
############################################

output "artifacts_bucket_name" {
  description = "S3 bucket name for dbt artifacts"
  value       = aws_s3_bucket.dbt_artifacts.id
}

output "artifacts_bucket_arn" {
  description = "S3 bucket ARN for dbt artifacts"
  value       = aws_s3_bucket.dbt_artifacts.arn
}

############################################
# NETWORKING
############################################

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

############################################
# STEP FUNCTIONS
############################################

output "step_function_arn" {
  description = "ARN of the Step Functions state machine"
  value       = var.enable_step_functions ? aws_sfn_state_machine.dbt[0].arn : null
}

output "step_function_name" {
  description = "Name of the Step Functions state machine"
  value       = var.enable_step_functions ? aws_sfn_state_machine.dbt[0].name : null
}

############################################
# ALERTING
############################################

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "dlq_url" {
  description = "Dead letter queue URL"
  value       = aws_sqs_queue.dlq.url
}

############################################
# SCHEDULES
############################################

output "scheduled_jobs" {
  description = "Map of scheduled job names to their schedule expressions"
  value = {
    for k, v in var.dbt_jobs : k => {
      schedule = v.schedule_expression
      enabled  = v.schedule_enabled
      command  = v.dbt_command
      select   = v.dbt_select
    }
  }
}

############################################
# USEFUL COMMANDS
############################################

output "manual_run_command" {
  description = "AWS CLI command to manually trigger a dbt job via Step Functions"
  value = var.enable_step_functions ? join("\n", [
    "# Run a specific model:",
    "aws stepfunctions start-execution \\",
    "  --state-machine-arn ${aws_sfn_state_machine.dbt[0].arn} \\",
    "  --input '{\"job_name\":\"manual\",\"dbt_command\":\"run\",\"dbt_select\":\"my_model\",\"dbt_exclude\":\"\",\"dbt_full_refresh\":\"false\"}'",
    "",
    "# Run with full refresh:",
    "aws stepfunctions start-execution \\",
    "  --state-machine-arn ${aws_sfn_state_machine.dbt[0].arn} \\",
    "  --input '{\"job_name\":\"manual\",\"dbt_command\":\"run\",\"dbt_select\":\"tag:incremental\",\"dbt_exclude\":\"\",\"dbt_full_refresh\":\"true\"}'",
    "",
    "# Run tests:",
    "aws stepfunctions start-execution \\",
    "  --state-machine-arn ${aws_sfn_state_machine.dbt[0].arn} \\",
    "  --input '{\"job_name\":\"manual\",\"dbt_command\":\"test\",\"dbt_select\":\"\",\"dbt_exclude\":\"\",\"dbt_full_refresh\":\"false\"}'"
  ]) : "Step Functions not enabled"
}