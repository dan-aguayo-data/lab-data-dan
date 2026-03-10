# ============================================
# ECS Cluster (Shared for both US and AU)
# ============================================

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

# ============================================
# Security Group - ECS Tasks
# ============================================
# Allows outbound to MSSQL and AWS services

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks"
  description = "Security group for MSSQL BCP export ECS tasks"
  vpc_id      = var.vpc_id

  # Allow outbound MSSQL connections to US and AU databases
 egress {
  description = "All outbound traffic for MSSQL, S3, Secrets Manager, CloudWatch"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

  tags = {
    Name = "${var.project_name}-ecs-tasks"
  }
}

# ============================================
# CloudWatch Log Groups
# ============================================

resource "aws_cloudwatch_log_group" "us_export" {
  name              = "/aws/ecs/${var.project_name}-us"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "au_export" {
  name              = "/aws/ecs/${var.project_name}-au"
  retention_in_days = var.log_retention_days
}

# ============================================
# ECS Task Definition - US Export
# ============================================

resource "aws_ecs_task_definition" "us_export" {
  family                   = "${var.project_name}-us-export"
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
    name      = "us-export"
    image     = "${aws_ecr_repository.bcp_export.repository_url}:latest"
    essential = true

    environment = [
      {
        name  = "REGION"
        value = "us"
      },
      {
        name  = "DATA_SOURCE"
        value = var.data_source_name
      },
      {
        name  = "DATABASE_NAME"
        value = var.us_database_name
      },
      {
        name  = "TABLES"
        value = var.us_tables_to_export
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
        value = tostring(var.us_bcp_batch_size)
      },
      {
        name  = "AWS_DEFAULT_REGION"
        value = var.aws_region
      }
    ]

    secrets = [
      {
        name      = "DB_CREDENTIALS"
        valueFrom = aws_secretsmanager_secret.us_credentials.arn
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.us_export.name
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
