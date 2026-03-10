# =============================================================================
# Step Function - Manual Trigger
# =============================================================================
# Trigger via AWS Console:
#   Step Functions > snowflake-key-generator > Start execution
#
# Input: {"service_account": "svc_dbt", "key_version": "rsa1"}
# =============================================================================

resource "aws_sfn_state_machine" "key_generator" {
  name     = local.name_prefix
  role_arn = aws_iam_role.sfn.arn

  definition = jsonencode({
    Comment = "Generate RSA keys for Snowflake service accounts"
    StartAt = "GenerateKeys"
    States = {
      GenerateKeys = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.key_generator.arn
          "Payload.$"  = "$"
        }
        ResultSelector = {
          "status.$"             = "$.Payload.status"
          "service_account.$"    = "$.Payload.service_account"
          "key_version.$"        = "$.Payload.key_version"
          "secrets_updated.$"    = "$.Payload.secrets_updated"
          "snowflake_user.$"     = "$.Payload.snowflake_user"
          "alter_user_command.$" = "$.Payload.alter_user_command"
          "message.$"            = "$.Payload.message"
        }
        End = true
        Catch = [{
          ErrorEquals = ["States.ALL"]
          ResultPath  = "$.error"
          Next        = "Failed"
        }]
      }
      Failed = {
        Type  = "Fail"
        Error = "KeyGenerationFailed"
        Cause = "Failed to generate RSA keys. Check CloudWatch logs."
      }
    }
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.sfn.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "sfn" {
  name              = "/aws/stepfunctions/${local.name_prefix}"
  retention_in_days = 14
  tags              = local.common_tags
}

# -----------------------------------------------------------------------------
# Step Function IAM Role
# -----------------------------------------------------------------------------

resource "aws_iam_role" "sfn" {
  name = "${local.name_prefix}-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "states.amazonaws.com" }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "sfn" {
  name = "${local.name_prefix}-sfn-policy"
  role = aws_iam_role.sfn.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = aws_lambda_function.key_generator.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# =============================================================================
# SNS Notifications (Optional)
# =============================================================================

resource "aws_sns_topic" "notifications" {
  count = var.notification_email != "" ? 1 : 0
  name  = "${local.name_prefix}-notifications"
  tags  = local.common_tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.notifications[0].arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# EventBridge rule for Step Function completion
resource "aws_cloudwatch_event_rule" "sfn_completion" {
  count       = var.notification_email != "" ? 1 : 0
  name        = "${local.name_prefix}-completion"
  description = "Notify on key generation completion"

  event_pattern = jsonencode({
    source      = ["aws.states"]
    detail-type = ["Step Functions Execution Status Change"]
    detail = {
      stateMachineArn = [aws_sfn_state_machine.key_generator.arn]
      status          = ["SUCCEEDED", "FAILED"]
    }
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "sns" {
  count = var.notification_email != "" ? 1 : 0
  rule  = aws_cloudwatch_event_rule.sfn_completion[0].name
  arn   = aws_sns_topic.notifications[0].arn

  input_transformer {
    input_paths = {
      status    = "$.detail.status"
      execution = "$.detail.executionArn"
    }
    input_template = "\"Snowflake Key Generation: <status>\\nExecution: <execution>\""
  }
}

resource "aws_sns_topic_policy" "allow_eventbridge" {
  count  = var.notification_email != "" ? 1 : 0
  arn    = aws_sns_topic.notifications[0].arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.notifications[0].arn
    }]
  })
}
