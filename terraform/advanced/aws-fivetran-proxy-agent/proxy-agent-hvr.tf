# proxy-agent-hvr.tf
# Fivetran Proxy Agent (HVR) Infrastructure

# ============================================================================
# DATA SOURCES
# ============================================================================

# Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Reference existing VPC
data "aws_vpc" "existing" {
  id = var.vpc_id
}

# Reference existing private subnet
data "aws_subnet" "existing" {
  id = var.subnet_id
}

# ============================================================================
# SECRETS MANAGER - Proxy Agent Configuration
# ============================================================================

# Read local config file
#locals {
#  proxy_config = jsondecode(file("${path.module}/fivetran-proxy-config.json"))
#}

# Store in Secrets Manager
resource "aws_secretsmanager_secret" "proxy_agent_config" {
  name                    = "data/fivetran/fivetran-proxy-agent-hvr-config"
  description             = "Fivetran Proxy Agent (HVR) Configuration"
  recovery_window_in_days = 0 # Immediate deletion for testing

  tags = {
    Name        = "Fivetran Proxy Agent Config"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

resource "aws_secretsmanager_secret_version" "proxy_agent_config" {
  secret_id     = aws_secretsmanager_secret.proxy_agent_config.id
  secret_string = var.fivetran_config
}

# ============================================================================
# SECURITY GROUP - Proxy Agent
# ============================================================================

resource "aws_security_group" "proxy_agent" {
  name        = "fivetran-proxy-agent-sg"
  description = "Security group for Fivetran Proxy Agent"
  vpc_id      = data.aws_vpc.existing.id

  # Outbound HTTPS (for Fivetran API)
  egress {
    description = "HTTPS to Fivetran"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound SQL Server (for database connection)
  egress {
    description = "SQL Server"
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound DNS
  egress {
    description = "DNS"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound NTP
  egress {
    description = "NTP"
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Fivetran Proxy Agent SG"
  }
}

# ============================================================================
# IAM ROLE & INSTANCE PROFILE
# ============================================================================

resource "aws_iam_role" "proxy_agent" {
  name = "fivetran-proxy-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "Fivetran Proxy Agent Role"
  }
}

# Policy for Secrets Manager access
resource "aws_iam_role_policy" "secrets_manager" {
  name = "secrets-manager-access"
  role = aws_iam_role.proxy_agent.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.proxy_agent_config.arn
      }
    ]
  })
}

# Attach SSM policy for remote management
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.proxy_agent.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch policy
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.proxy_agent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance Profile
resource "aws_iam_instance_profile" "proxy_agent" {
  name = "fivetran-proxy-agent-profile"
  role = aws_iam_role.proxy_agent.name
}

# ============================================================================
# CLOUDWATCH LOG GROUP
# ============================================================================

resource "aws_cloudwatch_log_group" "proxy_agent" {
  name              = "/aws/fivetran-proxy-agent"
  retention_in_days = 7

  tags = {
    Name = "Fivetran Proxy Agent Logs"
  }
}

# ============================================================================
# USER DATA SCRIPT
# ============================================================================

locals {
  user_data = templatefile("${path.module}/scripts/proxy-agent-setup-hvr.sh", {
    secret_arn       = aws_secretsmanager_secret.proxy_agent_config.arn
    aws_region       = var.aws_region
    hvr_version      = var.hvr_version
    hvr_download_url = var.hvr_download_url
  })
}

# ============================================================================
# EC2 INSTANCE - Fivetran Proxy Agent
# ============================================================================
# NOTE: The database security group must be configured by the infrastructure team
# to allow inbound connections from the Proxy Agent security group.
# See INFRA-TEAM-GUIDE.md for instructions.

resource "aws_instance" "proxy_agent" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.existing.id
  vpc_security_group_ids = [aws_security_group.proxy_agent.id]
  iam_instance_profile   = aws_iam_instance_profile.proxy_agent.name

  user_data                   = local.user_data
  user_data_replace_on_change = true

  root_block_device {
    volume_size           = 50
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "Fivetran Proxy Agent"
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.proxy_agent.id
}

output "private_ip" {
  description = "Private IP address of Proxy Agent"
  value       = aws_instance.proxy_agent.private_ip
}

output "proxy_agent_security_group_id" {
  description = "Security Group ID of Proxy Agent - provide this to infra team for database access"
  value       = aws_security_group.proxy_agent.id
}

output "secret_arn" {
  description = "ARN of Secrets Manager secret"
  value       = aws_secretsmanager_secret.proxy_agent_config.arn
}

output "log_group" {
  description = "CloudWatch Log Group name"
  value       = aws_cloudwatch_log_group.proxy_agent.name
}
