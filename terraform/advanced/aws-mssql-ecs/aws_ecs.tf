# ECS Cluster and Task Definition

resource "aws_ecs_cluster" "main" {
  name = var.project_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

# Security group for ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks"
  description = "Security group for SQL export ECS tasks"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound traffic for S3, Secrets Manager, ECR"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-tasks"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "export" {
  family                   = "${var.project_name}-export"
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
    name      = "export"
    image     = "${aws_ecr_repository.export.repository_url}:latest"
    essential = true

    environment = [
      {
        name  = "DB_NAME"
        value = var.database_name
      },
      {
        name  = "BACKUP_BUCKET"
        value = var.backup_bucket_name
      },
      {
        name  = "BACKUP_PREFIX"
        value = var.backup_prefix
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
        name  = "TABLES"
        value = var.tables_to_export
      },
      {
        name  = "AWS_DEFAULT_REGION"
        value = var.aws_region
      }
    ]

    secrets = [
      {
        name      = "SA_PASSWORD"
        valueFrom = aws_secretsmanager_secret.sa_password.arn
      },
      {
        name      = "MSSQL_SA_PASSWORD"
        valueFrom = aws_secretsmanager_secret.sa_password.arn
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.export.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
        mode                  = "non-blocking"
        max-buffer-size       = "25m"
      }
    }

    # Health check (optional - checks SQL Server startup)
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
