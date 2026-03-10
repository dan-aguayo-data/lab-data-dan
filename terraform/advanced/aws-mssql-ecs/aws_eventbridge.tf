# EventBridge Scheduler for Daily Execution

resource "aws_scheduler_schedule" "daily_export" {
  name       = "${var.project_name}-daily"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = var.schedule_expression

  target {
    arn      = aws_sfn_state_machine.data_export.arn
    role_arn = aws_iam_role.scheduler.arn

    input = jsonencode({
      # Input can be empty - container finds latest .bak automatically
      # Or override with specific parameters:
      # backupKey = "backups/specific/database.bak"
      # tables = "dbo.Table1,dbo.Table2"
    })

    retry_policy {
      maximum_event_age_in_seconds = 3600
      maximum_retry_attempts       = 2
    }
  }

  description = "Daily SQL Server backup export to S3"
}

# Optional: Manual trigger via EventBridge rule for ad-hoc runs
resource "aws_cloudwatch_event_rule" "manual_trigger" {
  name        = "${var.project_name}-manual-trigger"
  description = "Manual trigger for SQL export (invoke via console or CLI)"

  event_pattern = jsonencode({
    source      = ["custom.sqlexport"]
    detail-type = ["Manual Export Trigger"]
  })
}

resource "aws_cloudwatch_event_target" "manual_trigger" {
  rule      = aws_cloudwatch_event_rule.manual_trigger.name
  target_id = "StepFunctionsTarget"
  arn       = aws_sfn_state_machine.data_export.arn
  role_arn  = aws_iam_role.scheduler.arn
}

# To manually trigger:
# aws events put-events --entries '[{
#   "Source": "custom.sqlexport",
#   "DetailType": "Manual Export Trigger",
#   "Detail": "{}"
# }]'
