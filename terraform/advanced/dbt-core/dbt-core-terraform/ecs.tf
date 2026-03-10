############################################
# ECS CLUSTER
############################################

resource "aws_ecs_cluster" "main" {
  name = var.ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = var.ecs_cluster_name
  }
}

############################################
# ECS CLUSTER CAPACITY PROVIDERS
############################################

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

############################################
# ECS TASK DEFINITION - GENERIC DBT RUNNER
# This single task definition accepts runtime parameters
# for flexible job execution
############################################

resource "aws_ecs_task_definition" "dbt" {
  family                   = "${local.name_prefix}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.cpu_architecture
  }

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "dbt-runner"
      image     = local.ecr_image_url
      cpu       = var.fargate_cpu
      memory    = var.fargate_memory
      essential = true

      # Base environment variables - DBT_COMMAND, DBT_SELECT, etc. 
      # are passed at runtime via container overrides
      environment = [
        { name = "DBT_SNOWFLAKE_ACCOUNT", value = var.snowflake_org_account_name },
        { name = "DBT_SNOWFLAKE_USER", value = var.snowflake_dbt_user },
        { name = "DBT_SNOWFLAKE_ROLE", value = var.snowflake_dbt_role },
        { name = "DBT_DATABASE_DEV", value = var.dbt_target_database },
        { name = "DBT_SCHEMA_DEV", value = var.dbt_schema },
        { name = "DBT_WAREHOUSE", value = var.dbt_default_warehouse },
        { name = "DBT_TARGET", value = var.dbt_target },
        { name = "ARTIFACT_BUCKET_NAME", value = aws_s3_bucket.dbt_artifacts.id },
        { name = "AWS_REGION", value = var.aws_region }
      ]

   
      # Secret is plain text (not JSON) - use ARN directly without ::key::
      secrets = [
        {
          name      = "DBT_PRIVATE_KEY"
          valueFrom = data.aws_secretsmanager_secret.snowflake_dbt.arn
        },
        {
          name      = "GIT_TOKEN"
          valueFrom = data.aws_secretsmanager_secret.github_token.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "dbt"
        }
      }
    }
  ])

  tags = {
    Name = "${local.name_prefix}-task"
  }

  depends_on = [
    aws_ecr_repository.dbt,
    aws_s3_bucket.dbt_artifacts,
    aws_iam_role.ecs_task_execution_role,
    aws_iam_role.ecs_task_role,
    aws_cloudwatch_log_group.dbt
  ]
}
