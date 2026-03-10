# ============================================
# CloudWatch Dashboard
# ============================================

resource "aws_cloudwatch_dashboard" "main" {
  count          = var.enable_dashboard ? 1 : 0
  dashboard_name = var.project_name

  dashboard_body = jsonencode({
    widgets = [
      # Step Functions Execution Status
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/States", "ExecutionsFailed", { stat = "Sum", label = "Failed" }],
            [".", "ExecutionsSucceeded", { stat = "Sum", label = "Succeeded" }],
            [".", "ExecutionsTimedOut", { stat = "Sum", label = "Timed Out" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Step Functions Execution Status"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      # US Export Duration
      {
        type = "metric"
        properties = {
          metrics = [
            ["ECS/ContainerInsights", "TaskDuration", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "US Export Task Duration"
          yAxis = {
            left = {
              label = "Seconds"
            }
          }
        }
      },
      # AU Export Duration
      {
        type = "metric"
        properties = {
          metrics = [
            ["ECS/ContainerInsights", "TaskDuration", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "AU Export Task Duration"
          yAxis = {
            left = {
              label = "Seconds"
            }
          }
        }
      },
      # Custom Metrics - Rows Exported
      {
        type = "metric"
        properties = {
          metrics = [
            ["DataExport", "RowsExported", { stat = "Sum", label = "Total Rows" }],
            [".", "TablesExported", { stat = "Sum", label = "Tables Exported" }],
            [".", "TablesFailed", { stat = "Sum", label = "Tables Failed" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Export Metrics"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      # Log Insights - Recent Errors
      {
        type = "log"
        properties = {
          query   = <<-EOT
            SOURCE '${aws_cloudwatch_log_group.us_export.name}'
            | SOURCE '${aws_cloudwatch_log_group.au_export.name}'
            | fields @timestamp, @message
            | filter @message like /ERROR/
            | sort @timestamp desc
            | limit 20
          EOT
          region  = var.aws_region
          title   = "Recent Errors"
          stacked = false
        }
      },
      # ECS Task Count
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "RunningTasksCount", { stat = "Average" }]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "Active ECS Tasks"
        }
      }
    ]
  })
}

# ============================================
# CloudWatch Alarms
# ============================================

# Alarm: Step Functions Execution Failures
resource "aws_cloudwatch_metric_alarm" "sfn_failures" {
  alarm_name          = "${var.project_name}-sfn-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsFailed"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert when Step Functions execution fails"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.data_export.arn
  }
}

# Alarm: Step Functions Execution Timeout
resource "aws_cloudwatch_metric_alarm" "sfn_timeout" {
  alarm_name          = "${var.project_name}-sfn-timeout"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsTimedOut"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert when Step Functions execution times out"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.data_export.arn
  }
}

# Alarm: US Export Task Failures
resource "aws_cloudwatch_log_metric_filter" "us_export_failures" {
  name           = "${var.project_name}-us-failures"
  log_group_name = aws_cloudwatch_log_group.us_export.name
  pattern        = "[timestamp, level = ERROR*, ...]"

  metric_transformation {
    name      = "USExportErrors"
    namespace = "DataExport"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "us_export_failures" {
  alarm_name          = "${var.project_name}-us-export-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "USExportErrors"
  namespace           = "DataExport"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alert when US export has multiple errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
}

# Alarm: AU Export Task Failures
resource "aws_cloudwatch_log_metric_filter" "au_export_failures" {
  name           = "${var.project_name}-au-failures"
  log_group_name = aws_cloudwatch_log_group.au_export.name
  pattern        = "[timestamp, level = ERROR*, ...]"

  metric_transformation {
    name      = "AUExportErrors"
    namespace = "DataExport"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "au_export_failures" {
  alarm_name          = "${var.project_name}-au-export-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "AUExportErrors"
  namespace           = "DataExport"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alert when AU export has multiple errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"
}

# Alarm: Long Running Tasks (potential hanging)
resource "aws_cloudwatch_metric_alarm" "long_running_tasks" {
  alarm_name          = "${var.project_name}-long-running-tasks"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionTime"
  namespace           = "AWS/States"
  period              = 3600
  statistic           = "Maximum"
  threshold           = var.task_timeout_seconds * 0.9 # 90% of timeout
  alarm_description   = "Alert when tasks are running close to timeout"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.data_export.arn
  }
}
