############################################
# EVENTBRIDGE SCHEDULER GROUP
############################################

resource "aws_scheduler_schedule_group" "dbt" {
  name = "${local.name_prefix}-schedules"

  tags = {
    Name = "${local.name_prefix}-schedules"
  }
}

############################################
# EVENTBRIDGE SCHEDULES
# Dynamically created from dbt_jobs variable
# Triggers Step Functions (if enabled) or ECS directly
############################################

resource "aws_scheduler_schedule" "dbt_jobs" {
  for_each = var.dbt_jobs

  name        = "${local.name_prefix}-${each.key}"
  group_name  = aws_scheduler_schedule_group.dbt.name
  description = each.value.description

  schedule_expression          = each.value.schedule_expression
  schedule_expression_timezone = "Australia/Sydney"

  state = each.value.schedule_enabled ? "ENABLED" : "DISABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    # Use Step Functions if enabled, otherwise call ECS directly
    arn      = var.enable_step_functions ? aws_sfn_state_machine.dbt[0].arn : "arn:aws:ecs:${var.aws_region}:${local.account_id}:cluster/${aws_ecs_cluster.main.name}"
    role_arn = aws_iam_role.eventbridge_scheduler.arn

    # Input for Step Functions

    input = var.enable_step_functions ? jsonencode({
      job_name         = each.key
      dbt_command      = each.value.dbt_command
      dbt_select       = each.value.dbt_select != null ? each.value.dbt_select : ""
      dbt_exclude      = each.value.dbt_exclude != null ? each.value.dbt_exclude : ""
      dbt_full_refresh = each.value.dbt_full_refresh ? "true" : "false"
    }) : null

    # ECS parameters (used when Step Functions is disabled)
    dynamic "ecs_parameters" {
      for_each = var.enable_step_functions ? [] : [1]
      content {
        task_definition_arn = aws_ecs_task_definition.dbt.arn
        launch_type         = "FARGATE"
        platform_version    = var.fargate_platform_version
        task_count          = 1

        network_configuration {
          subnets          = aws_subnet.public[*].id
          assign_public_ip = true
          security_groups  = [aws_security_group.ecs_tasks.id]
        }
      }
    }

    # Retry policy
    retry_policy {
      maximum_event_age_in_seconds = 3600
      maximum_retry_attempts       = 2
    }

    # Dead letter queue
    dead_letter_config {
      arn = aws_sqs_queue.dlq.arn
    }
  }
}

############################################
# DEAD LETTER QUEUE
############################################

resource "aws_sqs_queue" "dlq" {
  name                      = "${local.name_prefix}-dlq"
  message_retention_seconds = 1209600  # 14 days

  tags = {
    Name = "${local.name_prefix}-dlq"
  }
}

############################################
# SNS TOPIC FOR ALERTS
############################################

resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"

  tags = {
    Name = "${local.name_prefix}-alerts"
  }
}

############################################
# SNS EMAIL SUBSCRIPTION
############################################

resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.dbt_email_alerts
}

############################################
# CLOUDWATCH ALARMS FOR DLQ
############################################

resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "${local.name_prefix}-dlq-has-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alerts when failed dbt jobs appear in DLQ"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${local.name_prefix}-dlq-alarm"
  }
}
