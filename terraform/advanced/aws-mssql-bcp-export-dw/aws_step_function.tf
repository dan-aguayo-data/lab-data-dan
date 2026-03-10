# ============================================
# Step Functions State Machine
# ============================================
# Orchestrates US and AU database exports

resource "aws_sfn_state_machine" "data_export" {
  name     = var.project_name
  role_arn = aws_iam_role.sfn_execution.arn

  definition = var.execution_mode == "parallel" ? jsonencode({
    Comment = "MSSQL BCP Export - Parallel execution of US and AU exports"
    StartAt = "ParallelExport"
    States = {
      ParallelExport = {
        Type = "Parallel"
        Branches = [
          # US Export Branch
          var.enable_us_export ? {
            StartAt = "RunUSExport"
            States = {
              RunUSExport = {
                Type     = "Task"
                Resource = "arn:aws:states:::ecs:runTask.sync"
                Parameters = {
                  Cluster        = aws_ecs_cluster.main.arn
                  TaskDefinition = aws_ecs_task_definition.us_export.arn
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
                      Name = "us-export"
                      Environment = [
                        {
                          Name       = "JOB_ID"
                          "Value.$" = "States.Format('us-export-{}', $$.Execution.Name)"
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
                End = true
              }
            }
          } : null,
          # AU Export Branch
          var.enable_au_export ? {
            StartAt = "RunAUExport"
            States = {
              RunAUExport = {
                Type     = "Task"
                Resource = "arn:aws:states:::ecs:runTask.sync"
                Parameters = {
                  Cluster        = aws_ecs_cluster.main.arn
                  TaskDefinition = aws_ecs_task_definition.au_export.arn
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
                      Name = "au-export"
                      Environment = [
                        {
                          Name       = "JOB_ID"
                          "Value.$" = "States.Format('au-export-{}', $$.Execution.Name)"
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
                End = true
              }
            }
          } : null
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
        Next = "CheckResults"
      }

      CheckResults = {
        Type = "Choice"
        Choices = [
          {
            And = [
              var.enable_us_export ? {
                Variable      = "$[0].Containers[0].ExitCode"
                NumericEquals = 0
              } : null,
              var.enable_au_export ? {
                Variable      = "$[1].Containers[0].ExitCode"
                NumericEquals = 0
              } : null
            ]
            Next = "NotifySuccess"
          }
        ]
        Default = "NotifyPartialFailure"
      }

      NotifySuccess = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = aws_sns_topic.notifications.arn
          Subject  = "✅ MSSQL Export Completed Successfully"
          Message = {
            ".$" = "States.Format('Export job {} completed successfully for all enabled regions.', $$.Execution.Name)"
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

      NotifyPartialFailure = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = aws_sns_topic.alerts.arn
          Subject  = "⚠️ MSSQL Export Completed with Failures"
          Message = {
            ".$" = "States.Format('Export job {} completed but some regions failed. Check CloudWatch logs for details.', $$.Execution.Name)"
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
              StringValue = "PARTIAL_FAILURE"
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
          Subject  = "🚨 MSSQL Export Failed"
          Message = {
            ".$" = "States.Format('Export job {} failed completely. Error: {}', $$.Execution.Name, $.error.Cause)"
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
  }) : jsonencode({
    Comment = "MSSQL BCP Export - Sequential execution (US then AU)"
    StartAt = "RunUSExport"
    States = {
      RunUSExport = {
        Type     = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          Cluster        = aws_ecs_cluster.main.arn
          TaskDefinition = aws_ecs_task_definition.us_export.arn
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
              Name = "us-export"
              Environment = [
                {
                  Name       = "JOB_ID"
                  "Value.$" = "States.Format('us-export-{}', $$.Execution.Name)"
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
        Next = "RunAUExport"
      }

      RunAUExport = {
        Type     = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          Cluster        = aws_ecs_cluster.main.arn
          TaskDefinition = aws_ecs_task_definition.au_export.arn
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
              Name = "au-export"
              Environment = [
                {
                  Name       = "JOB_ID"
                  "Value.$" = "States.Format('au-export-{}', $$.Execution.Name)"
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
        Next = "NotifySuccess"
      }

      NotifySuccess = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = aws_sns_topic.notifications.arn
          Subject  = "✅ MSSQL Export Completed Successfully"
          Message = {
            ".$" = "States.Format('Export job {} completed successfully.', $$.Execution.Name)"
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
          Subject  = "🚨 MSSQL Export Failed"
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

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.sfn.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  tracing_configuration {
    enabled = true
  }
}

# CloudWatch Log Group for Step Functions
resource "aws_cloudwatch_log_group" "sfn" {
  name              = "/aws/vendedlogs/states/${var.project_name}"
  retention_in_days = var.log_retention_days
}

# ============================================
# EventBridge Schedule
# ============================================

resource "aws_cloudwatch_event_rule" "schedule" {
  count               = var.enable_schedule ? 1 : 0
  name                = "${var.project_name}-schedule"
  description         = "Scheduled execution of MSSQL BCP export pipeline"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "sfn" {
  count     = var.enable_schedule ? 1 : 0
  rule      = aws_cloudwatch_event_rule.schedule[0].name
  target_id = "step-function"
  arn       = aws_sfn_state_machine.data_export.arn
  role_arn  = aws_iam_role.eventbridge.arn
}
