# =============================================================================
# Main Terraform Configuration - Index Maintenance Infrastructure
# =============================================================================

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  # S3 Backend with DynamoDB locking
  backend "s3" {
    bucket         = "eft-data-terraform-backend"
      # key provided via -backend-config    e.g. terraform init -backend-config=""
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-lock-data-mssql-ix-maintenance"
    encrypt        = true
 
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = merge(var.tags, {
      Project     = var.project_name
      Environment = var.environment
      Region      = var.aws_region
      ManagedBy   = "terraform"
    })
  }
}

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------
locals {
  # Short region codes for naming
  region_short = {
    "ap-southeast-2" = "au"
    "us-east-1"      = "us"
    "us-west-2"      = "usw"
    "eu-west-1"      = "eu"
  }
  
  region_code = lookup(local.region_short, var.aws_region, replace(var.aws_region, "-", ""))
  
  # Standard prefix for regional resources (Lambda, Step Functions, etc.)
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Prefix for global resources (IAM roles) - includes region to avoid conflicts
  global_name_prefix = "${var.project_name}-${var.environment}-${local.region_code}"
}

# -----------------------------------------------------------------------------
# Security Group for Lambda
# -----------------------------------------------------------------------------
resource "aws_security_group" "lambda" {
  name        = "${local.name_prefix}-lambda-sg"
  description = "Security group for index maintenance Lambda - SQL Server access"
  vpc_id      = var.vpc_id

  # Outbound to SQL Server
  egress {
    description = "SQL Server access"
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  # Outbound HTTPS for Secrets Manager and CloudWatch
  egress {
    description = "HTTPS for AWS services"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-lambda-sg"
  }
}

# -----------------------------------------------------------------------------
# SNS Topic for Alerts
# -----------------------------------------------------------------------------
resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"
}

resource "aws_sns_topic_subscription" "email_alerts" {
  for_each = toset(var.alert_email_addresses)

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

# -----------------------------------------------------------------------------
# IAM Role for Lambda (Global resource - uses region suffix)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "lambda_role" {
  name = "${local.global_name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${local.global_name_prefix}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:*"
      },
      {
        Sid    = "SecretsManager"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.db_secret_arn
      },
      {
        Sid    = "VPCAccess"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = "*"
      },
      {
        Sid    = "SNSPublish"
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Lambda Function Package
# -----------------------------------------------------------------------------
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda_function.zip"
}

# -----------------------------------------------------------------------------
# Lambda Function
# -----------------------------------------------------------------------------
resource "aws_lambda_function" "index_maintenance" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.name_prefix}-executor"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index_maintenance.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.11"
  timeout          = var.lambda_timeout_seconds
  memory_size      = 256

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_SECRET_ARN             = var.db_secret_arn
      DATABASE_NAME             = var.database_name
      INCLUDE_TABLES            = var.include_tables
      EXCLUDE_TABLES            = var.exclude_tables
      PROCEDURE_TIMEOUT_SECONDS = tostring(var.procedure_timeout_seconds)
      SNS_TOPIC_ARN             = aws_sns_topic.alerts.arn
    }
  }

  layers = var.lambda_layer_arns
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.index_maintenance.function_name}"
  retention_in_days = 30
}

# -----------------------------------------------------------------------------
# IAM Role for Step Functions (Global resource - uses region suffix)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "step_functions_role" {
  name = "${local.global_name_prefix}-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "step_functions_policy" {
  name = "${local.global_name_prefix}-sfn-policy"
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InvokeLambda"
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.index_maintenance.arn
      },
      {
        Sid    = "SNSPublish"
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.alerts.arn
      },
      {
        Sid    = "CloudWatchLogs"
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

# -----------------------------------------------------------------------------
# Step Functions State Machine
# -----------------------------------------------------------------------------
resource "aws_sfn_state_machine" "index_maintenance" {
  name     = var.step_function_name != "" ? var.step_function_name : "${local.name_prefix}-workflow"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "Index Maintenance Workflow - Collect Stats, Perform Maintenance, Verify"
    StartAt = "CollectIndexStats"
    States = {
      CollectIndexStats = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.index_maintenance.arn
          Payload = {
            action = "collect_stats"
          }
        }
        ResultPath = "$.collectStatsResult"
        TimeoutSeconds = var.lambda_timeout_seconds
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "NotifyFailure"
          }
        ]
        Next = "PerformMaintenance"
      }

      PerformMaintenance = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.index_maintenance.arn
          Payload = {
            action = "perform_maintenance"
          }
        }
        ResultPath = "$.maintenanceResult"
        TimeoutSeconds = var.lambda_timeout_seconds
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "NotifyFailure"
          }
        ]
        Next = "CollectPostMaintenanceStats"
      }

      CollectPostMaintenanceStats = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.index_maintenance.arn
          Payload = {
            action = "collect_stats"
          }
        }
        ResultPath = "$.postMaintenanceResult"
        TimeoutSeconds = var.lambda_timeout_seconds
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "NotifyFailure"
          }
        ]
        Next = "NotifySuccess"
      }

      NotifySuccess = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = aws_sns_topic.alerts.arn
          Subject  = "[SUCCESS] Index Maintenance - ${var.environment}"
          Message  = "Index maintenance completed successfully. Check CloudWatch logs and IndexMaintenanceLog table for details."
        }
        End = true
      }

      NotifyFailure = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = aws_sns_topic.alerts.arn
          Subject  = "[FAILURE] Index Maintenance - ${var.environment}"
          Message  = "Index maintenance FAILED. Check Step Functions execution history and CloudWatch logs for error details."
        }
        Next = "FailWorkflow"
      }

      FailWorkflow = {
        Type  = "Fail"
        Error = "IndexMaintenanceFailed"
        Cause = "One or more steps in the index maintenance workflow failed"
      }
    }
  })
}

# -----------------------------------------------------------------------------
# EventBridge Rule (Scheduler)
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${local.name_prefix}-schedule"
  description         = "Triggers index maintenance workflow"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "step_function" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "TriggerStepFunction"
  arn       = aws_sfn_state_machine.index_maintenance.arn
  role_arn  = aws_iam_role.eventbridge_role.arn
}

# -----------------------------------------------------------------------------
# IAM Role for EventBridge (Global resource - uses region suffix)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "eventbridge_role" {
  name = "${local.global_name_prefix}-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "eventbridge_policy" {
  name = "${local.global_name_prefix}-eventbridge-policy"
  role = aws_iam_role.eventbridge_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution"
        ]
        Resource = aws_sfn_state_machine.index_maintenance.arn
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.index_maintenance.arn
}

output "lambda_security_group_id" {
  description = "Security group ID of the Lambda function - add inbound rule to your EC2/RDS SG allowing this SG on port 1433"
  value       = aws_security_group.lambda.id
}

output "step_function_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.index_maintenance.arn
}

output "step_function_name" {
  description = "Name of the Step Functions state machine"
  value       = aws_sfn_state_machine.index_maintenance.name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.schedule.arn
}

output "region_code" {
  description = "Short region code used in naming"
  value       = local.region_code
}
