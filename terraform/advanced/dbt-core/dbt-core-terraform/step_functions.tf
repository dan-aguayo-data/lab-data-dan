############################################
# STEP FUNCTIONS STATE MACHINE
# Provides orchestration with retry logic, error handling,
# and notifications
############################################

resource "aws_sfn_state_machine" "dbt" {
  count = var.enable_step_functions ? 1 : 0

  name     = "${local.name_prefix}-orchestrator"
  role_arn = aws_iam_role.step_functions[0].arn

  definition = jsonencode({
    Comment = "dbt Core orchestration with retry and error handling"
    StartAt = "RunDbtTask"
    States = {
      RunDbtTask = {
        Type     = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        ResultPath = "$.taskResult"
        Parameters = {
          Cluster        = aws_ecs_cluster.main.arn
          TaskDefinition = aws_ecs_task_definition.dbt.arn
          LaunchType     = "FARGATE"
          PlatformVersion = var.fargate_platform_version
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets        = aws_subnet.public[*].id
              AssignPublicIp = "ENABLED"
              SecurityGroups = [aws_security_group.ecs_tasks.id]
            }
          }
          Overrides = {
            ContainerOverrides = [
              {
                Name = "dbt-runner"
                Environment = [
                  { "Name" = "DBT_COMMAND", "Value.$" = "$.dbt_command" },
                  { "Name" = "DBT_SELECT", "Value.$" = "States.Format('{}', $.dbt_select)" },
                  { "Name" = "DBT_EXCLUDE", "Value.$" = "States.Format('{}', $.dbt_exclude)" },
                  { "Name" = "DBT_FULL_REFRESH", "Value.$" = "States.Format('{}', $.dbt_full_refresh)" },
                  { "Name" = "JOB_NAME", "Value.$" = "$.job_name" }
                ]
              }
            ]
          }
        }
        Retry = [
          {
            ErrorEquals = [
              "States.TaskFailed",
              "ECS.AmazonECSException"
            ]
            IntervalSeconds = var.step_function_retry_interval
            MaxAttempts     = var.step_function_retry_attempts
            BackoffRate     = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next        = "NotifyFailure"
            ResultPath  = "$.error"
          }
        ]
        Next = "NotifySuccess"
      }

      NotifySuccess = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = aws_sns_topic.alerts.arn
          Subject  = "dbt job succeeded"
          "Message.$" = "States.Format('dbt job {} completed successfully. Command: {}, Select: {}', $.job_name, $.dbt_command, $.dbt_select)"
        }
        End = true
      }

      NotifyFailure = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = aws_sns_topic.alerts.arn
          Subject  = "dbt job failed"
          "Message.$" = "States.Format('dbt job {} FAILED. Command: {}, Select: {}', $.job_name, $.dbt_command, $.dbt_select)"
        }
        Next = "FailExecution"
      }

      FailExecution = {
        Type  = "Fail"
        Error = "DbtJobFailed"
        Cause = "dbt task failed after all retry attempts"
      }
    }
  })


  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.step_functions[0].arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  tags = {
    Name = "${local.name_prefix}-orchestrator"
  }

  depends_on = [
    aws_iam_role_policy.step_functions
  ]
}
