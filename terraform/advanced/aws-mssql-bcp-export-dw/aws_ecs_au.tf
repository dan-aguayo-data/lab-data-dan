# ============================================
# ECS Task Definition - AU Export
# ============================================

resource "aws_ecs_task_definition" "au_export" {
  family                   = "${var.project_name}-au-export"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  ephemeral_storage {
    size_in_gib = var.fargate_ephemeral_storage
  }

  container_definitions = jsonencode([{
    name      = "au-export"
    image     = "${aws_ecr_repository.bcp_export.repository_url}:latest"
    essential = true

    environment = [
      {
        name  = "REGION"
        value = "au"
      },
      {
        name  = "DATA_SOURCE"
        value = var.data_source_name
      },
      {
        name  = "DATABASE_NAME"
        value = var.au_database_name
      },
      {
        name  = "TABLES"
        value = var.au_tables_to_export
      },
      {
        name  = "OUTPUT_BUCKET"
        value = var.export_bucket_name
      },
      {
        name  = "OUTPUT_PREFIX"
        value = var.export_prefix
      },
      {
        name  = "BCP_BATCH_SIZE"
        value = tostring(var.au_bcp_batch_size)
      },
      {
        name  = "AWS_DEFAULT_REGION"
        value = var.aws_region
      }
    ]

    secrets = [
      {
        name      = "DB_CREDENTIALS"
        valueFrom = aws_secretsmanager_secret.au_credentials.arn
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.au_export.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
        mode                  = "non-blocking"
        max-buffer-size       = "25m"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "exit 0"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}
