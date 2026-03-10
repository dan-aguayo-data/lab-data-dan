# ═══════════════════════════════════════════════════════
# EC2 — Windows Server with SQL Server Standard
#
# SQL Server comes pre-installed on the AMI.
# User data installs SSMS, configures TCP/IP, mixed auth,
# opens firewall, and sets SA password.
# ═══════════════════════════════════════════════════════

# ─── Windows + SQL Server Standard AMI (ap-southeast-2) ─
locals {
  sql_server_ami = "ami-065f55a5dcb110f0e"
}

# ─── IAM role for EC2 (SSM access + S3 if needed) ─────
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# ─── Key Pair for RDP (optional — can also use SSM) ────
resource "tls_private_key" "ec2" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "ec2" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.ec2.public_key_openssh
}

resource "local_file" "ec2_private_key" {
  content  = tls_private_key.ec2.private_key_pem
  filename = "${path.module}/vpn-config/${var.project_name}-key.pem"
}

# ─── EC2 Instance ──────────────────────────────────────
resource "aws_instance" "mssql" {
  ami                    = local.sql_server_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.mssql.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  key_name               = aws_key_pair.ec2.key_name

  root_block_device {
    volume_size = var.ec2_volume_size
    volume_type = "gp3"
    iops        = 6000
    throughput  = 500   # MiB/s — max for gp3 is 1000
    encrypted   = true
  }

  user_data = templatefile("${path.module}/scripts/userdata.ps1", {
    sa_password = var.sa_password
  })

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2 enforced
  }

  tags = {
    Name = "${var.project_name}-mssql"
  }

  # Give the NAT gateway time to be ready before bootstrap
  depends_on = [aws_nat_gateway.main]
}
