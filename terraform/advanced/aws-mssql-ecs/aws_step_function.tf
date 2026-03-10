# Step Functions State Machine for SQL Export Orchestration

resource "aws_sfn_state_machine" "data_export" {
  name     = "${var.project_name}-export"
  role_arn = aws_iam_role.sfn_execution.arn

  definition = jsonencode({
    Comment = "SQL Server .bak restore and export to S3"
    StartAt = "RunExportTask"
    States = {
      RunExportTask = {
        Type     = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          Cluster        = aws_ecs_cluster.main.arn
          TaskDefinition = aws_ecs_task_definition.export.arn
          LaunchType     = "FARGATE"
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets        = var.private_subnet_ids
              SecurityGroups = [aws_security_group.ecs_tasks.id]
              AssignPublicIp = "DISABLED"
            }
          }
          Overrides = {
            ContainerOverrides = [{
              Name = "export"
              Environment = [
                {
                  Name  = "JOB_ID"
                  "Value.$" = "$$.Execution.Name"
                }
              ]
            }]
          }
        }
        TimeoutSeconds = var.task_timeout_seconds
        Retry = [
          {
            ErrorEquals = [
              "States.TaskFailed"
            ]
            IntervalSeconds = 120
            MaxAttempts     = 2
            BackoffRate     = 2
          }
        ]
        Catch = [
          {
            ErrorEquals = [
              "States.ALL"
            ]
            ResultPath = "$.error"
            Next       = "NotifyFailure"
          }
        ]
        Next = "CheckExportSuccess"
      }

      CheckExportSuccess = {
        Type = "Choice"
        Choices = [
          {
            Variable      = "$.Containers[0].ExitCode"
            NumericEquals = 0
            Next          = "NotifySuccess"
          }
        ]
        Default = "NotifyFailure"
      }

      NotifySuccess = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = aws_sns_topic.notifications.arn
          Subject  = "✅ SQL Export Completed Successfully"
          Message = {
            ".$" = "States.Format('Export job {} completed successfully', $$.Execution.Name)"
          }
          MessageAttributes = {
            JobId = {
              DataType = "String"
              StringValue = {
                ".$" = "$$.Execution.Name"
              }
            }
            Status = {
              DataType    = "String"
              StringValue = "SUCCESS"
            }
          }
        }
        End = true
      }

      NotifyFailure = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = aws_sns_topic.alerts.arn
          Subject  = "🚨 SQL Export Failed"
          Message = {
            ".$" = "States.Format('Export job {} failed. Error: {}', $$.Execution.Name, $.error.Cause)"
          }
          MessageAttributes = {
            JobId = {
              DataType = "String"
              StringValue = {
                ".$" = "$$.Execution.Name"
              }
            }
            Status = {
              DataType    = "String"
              StringValue = "FAILED"
            }
          }
        }
        End = true
      }
    }
  })

  # Logging temporarily disabled - uncomment after fixing IAM permissions
  # logging_configuration {
  #   log_destination        = "${aws_cloudwatch_log_group.sfn.arn}:*"
  #   include_execution_data = true
  #   level                  = "ALL"
  # }

  # tracing_configuration {
  #   enabled = true
  # }
}
