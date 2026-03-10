# CloudWatch Log Groups, Metrics, and Dashboard

# Log Group for ECS tasks
resource "aws_cloudwatch_log_group" "export" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = var.log_retention_days

  kms_key_id = var.environment == "prod" ? aws_kms_key.logs[0].arn : null
}

# Log Group for Step Functions
resource "aws_cloudwatch_log_group" "sfn" {
  name              = "/aws/vendedlogs/states/${var.project_name}"
  retention_in_days = var.log_retention_days

  kms_key_id = var.environment == "prod" ? aws_kms_key.logs[0].arn : null
}

# KMS key for log encryption in prod
resource "aws_kms_key" "logs" {
  count = var.environment == "prod" ? 1 : 0

  description             = "KMS key for ${var.project_name} logs"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}"
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "logs" {
  count = var.environment == "prod" ? 1 : 0

  name          = "alias/${var.project_name}-logs"
  target_key_id = aws_kms_key.logs[0].key_id
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "pipeline_failure" {
  alarm_name          = "${var.project_name}-execution-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsFailed"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "SQL export pipeline failed"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.data_export.arn
  }
}

resource "aws_cloudwatch_metric_alarm" "pipeline_timeout" {
  alarm_name          = "${var.project_name}-execution-timeout"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionTime"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Maximum"
  threshold           = var.task_timeout_seconds * 1000  # Convert to milliseconds
  alarm_description   = "SQL export pipeline exceeded timeout"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.data_export.arn
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "pipeline" {
  count = var.enable_dashboard ? 1 : 0

  dashboard_name = "${var.project_name}-pipeline"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          title   = "Step Functions Executions"
          region  = var.aws_region
          metrics = [
            ["AWS/States", "ExecutionsSucceeded", "StateMachineArn", aws_sfn_state_machine.data_export.arn, { color = "#2ca02c", label = "Success" }],
            [".", "ExecutionsFailed", ".", ".", { color = "#d62728", label = "Failed" }],
            [".", "ExecutionsStarted", ".", ".", { color = "#1f77b4", label = "Started" }]
          ]
          period = 86400
          stat   = "Sum"
          view   = "timeSeries"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "Execution Duration"
          region = var.aws_region
          metrics = [
            ["AWS/States", "ExecutionTime", "StateMachineArn", aws_sfn_state_machine.data_export.arn, { stat = "Average", label = "Avg Duration" }],
            ["...", { stat = "Maximum", label = "Max Duration" }]
          ]
          period = 86400
          view   = "timeSeries"
          yAxis = {
            left = {
              label = "Milliseconds"
              min   = 0
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "ECS Task Resource Usage"
          region = var.aws_region
          metrics = [
            ["ECS/ContainerInsights", "CpuUtilized", "TaskDefinitionFamily", "${var.project_name}-export", "ClusterName", aws_ecs_cluster.main.name, { label = "CPU" }],
            [".", "MemoryUtilized", ".", ".", ".", ".", { label = "Memory" }]
          ]
          period = 300
          stat   = "Average"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Custom Metrics - Data Volume"
          region = var.aws_region
          metrics = [
            ["DataExport", "RowsExported", { stat = "Sum", period = 86400, label = "Total Rows" }],
            [".", "TablesExported", { stat = "Sum", period = 86400, label = "Tables" }],
            [".", "TablesFailed", { stat = "Sum", period = 86400, label = "Failed Tables", color = "#d62728" }]
          ]
          view   = "timeSeries"
          period = 86400
        }
      },
      {
        type   = "log"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Recent Export Jobs"
          region = var.aws_region
          query  = <<-EOT
            SOURCE '${aws_cloudwatch_log_group.export.name}'
            | filter @message like /SUCCESS|ERROR|Starting job/
            | parse @message "Starting job: *" as job_id
            | parse @message "SUCCESS: * - * rows" as table, rows
            | fields @timestamp, job_id, table, rows, @message
            | sort @timestamp desc
            | limit 20
          EOT
          view = "table"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Restore Duration Trend"
          region = var.aws_region
          query  = <<-EOT
            SOURCE '${aws_cloudwatch_log_group.export.name}'
            | filter @message like /RestoreDurationSeconds/
            | parse @message '"RestoreDurationSeconds":*' as restore_time
            | stats avg(restore_time) as avg_restore_seconds by bin(1d)
          EOT
          view = "timeSeries"
        }
      },
      {
        type   = "log"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Error Log"
          region = var.aws_region
          query  = <<-EOT
            SOURCE '${aws_cloudwatch_log_group.export.name}'
            | filter @message like /ERROR|WARN|Failed/
            | fields @timestamp, @message
            | sort @timestamp desc
            | limit 50
          EOT
          view = "table"
        }
      }
    ]
  })
}

# Data sources
data "aws_caller_identity" "current" {}
