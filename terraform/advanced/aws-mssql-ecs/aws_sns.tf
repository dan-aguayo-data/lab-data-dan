# SNS Topics for Notifications and Alerts

resource "aws_sns_topic" "notifications" {
  name         = "${var.project_name}-notifications"
  display_name = "SQL Export Pipeline Notifications"

  kms_master_key_id = var.environment == "prod" ? aws_kms_key.sns[0].id : null
}

resource "aws_sns_topic" "alerts" {
  name         = "${var.project_name}-alerts"
  display_name = "SQL Export Pipeline Alerts"

  kms_master_key_id = var.environment == "prod" ? aws_kms_key.sns[0].id : null
}

# Email subscription for notifications (success messages)
resource "aws_sns_topic_subscription" "notifications_email" {
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = var.alert_email

  filter_policy = jsonencode({
    Status = ["SUCCESS"]
  })
}

# Email subscription for alerts (failures)
resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# KMS key for SNS encryption in prod
resource "aws_kms_key" "sns" {
  count = var.environment == "prod" ? 1 : 0

  description             = "KMS key for ${var.project_name} SNS topics"
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
        Sid    = "Allow SNS"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow Step Functions to publish"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "sns" {
  count = var.environment == "prod" ? 1 : 0

  name          = "alias/${var.project_name}-sns"
  target_key_id = aws_kms_key.sns[0].key_id
}

# SNS topic policy to allow Step Functions to publish
resource "aws_sns_topic_policy" "notifications" {
  arn = aws_sns_topic.notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowStepFunctionsPublish"
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
      Action   = "sns:Publish"
      Resource = aws_sns_topic.notifications.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sfn_state_machine.data_export.arn
        }
      }
    }]
  })
}

resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowStepFunctionsPublish"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.alerts.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sfn_state_machine.data_export.arn
          }
        }
      },
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}
