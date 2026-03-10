variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "dev-mssql"
}

# ─── VPC ───────────────────────────────────────────────
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.50.0.0/16"
}

variable "private_subnet_cidr" {
  description = "CIDR for private subnet (EC2 lives here)"
  type        = string
  default     = "10.50.1.0/24"
}

variable "public_subnet_cidr" {
  description = "CIDR for public subnet (NAT Gateway lives here)"
  type        = string
  default     = "10.50.100.0/24"
}

variable "availability_zone" {
  description = "AZ for subnets"
  type        = string
  default     = "ap-southeast-2a"
}

# ─── VPN ───────────────────────────────────────────────
variable "vpn_client_cidr" {
  description = "CIDR block assigned to VPN clients (must not overlap VPC CIDR)"
  type        = string
  default     = "10.100.0.0/22"
}

# ─── EC2 ───────────────────────────────────────────────
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "m5.xlarge" # 4 vCPU, 16 GB — good for SQL Server Dev
}

variable "ec2_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 100
}

variable "sa_password" {
  description = "SQL Server SA password"
  type        = string
  sensitive   = true
}

variable "allowed_rdp_cidrs" {
  description = "Additional CIDRs allowed to RDP (beyond VPN). Leave empty for VPN-only."
  type        = list(string)
  default     = []
}
