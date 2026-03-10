# ============================================
# VPC Endpoints - Complete Configuration
# ============================================
# Creates all necessary VPC endpoints for ECS tasks to access AWS services
# Uses existing vpc-endpoints-sg security group

# Reference existing VPC endpoints security group
data "aws_security_group" "vpc_endpoints" {
  vpc_id = var.vpc_id
  
  filter {
    name   = "group-name"
    values = ["vpc-endpoints-sg"]
  }
}

# ============================================
# Interface Endpoints
# ============================================

# Secrets Manager - for fetching DB credentials
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.private_subnet_ids[0]]  # Use first subnet only
  security_group_ids  = [data.aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-secretsmanager"
  }
}

# ECR API - for Docker authentication
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.private_subnet_ids[0]]
  security_group_ids  = [data.aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-ecr-api"
  }
}

# ECR Docker - for pulling Docker images
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.private_subnet_ids[0]]
  security_group_ids  = [data.aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-ecr-dkr"
  }
}

# CloudWatch Logs - for writing container logs
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.private_subnet_ids[0]]
  security_group_ids  = [data.aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-logs"
  }
}

# ============================================
# Gateway Endpoint (Free!)
# ============================================



# Auto-discover route tables if not provided
data "aws_route_table" "private" {
  count     = length(var.route_table_ids) == 0 ? length(distinct(var.private_subnet_ids)) : 0
  subnet_id = distinct(var.private_subnet_ids)[count.index]
}

# S3 - for uploading exported files
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  
  # Use provided route tables or auto-discovered ones
  route_table_ids = length(var.route_table_ids) > 0 ? var.route_table_ids : distinct(data.aws_route_table.private[*].id)

  tags = {
    Name = "${var.project_name}-s3"
  }
}


# ============================================
# Security Group Rule
# ============================================

resource "aws_security_group_rule" "vpc_endpoints_from_ecs" {
  description              = "Allow HTTPS from ECS tasks to VPC endpoints"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_tasks.id
  security_group_id        = data.aws_security_group.vpc_endpoints.id
}
