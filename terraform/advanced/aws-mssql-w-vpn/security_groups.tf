# ═══════════════════════════════════════════════════════
# Security Groups — mirrors RDS firewall pattern
#
# Inbound:
#   - 1433 (SQL Server) from VPN clients + VPC internal
#   - 3389 (RDP) from VPN clients + VPC (VPN NAT)
# Outbound:
#   - All (for SSMS install, Windows Update, S3 access)
# ═══════════════════════════════════════════════════════

resource "aws_security_group" "mssql" {
  name        = "${var.project_name}-mssql"
  description = "Dev MSSQL - VPN-only access (mirrors RDS pattern)"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.project_name}-mssql-sg" }
}

# ─── Inbound: SQL Server 1433 from VPN clients ────────
resource "aws_vpc_security_group_ingress_rule" "sql_from_vpn" {
  security_group_id = aws_security_group.mssql.id
  description       = "SQL Server from VPN clients"
  from_port         = 1433
  to_port           = 1433
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpn_client_cidr
}

# ─── Inbound: SQL Server 1433 from within VPC ─────────
resource "aws_vpc_security_group_ingress_rule" "sql_from_vpc" {
  security_group_id = aws_security_group.mssql.id
  description       = "SQL Server from VPC (ECS tasks, other services)"
  from_port         = 1433
  to_port           = 1433
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr
}

# ─── Inbound: RDP 3389 from VPN clients ───────────────
resource "aws_vpc_security_group_ingress_rule" "rdp_from_vpn" {
  security_group_id = aws_security_group.mssql.id
  description       = "RDP from VPN clients"
  from_port         = 3389
  to_port           = 3389
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpn_client_cidr
}

# ─── Inbound: RDP 3389 from within VPC (VPN NAT) ──────
resource "aws_vpc_security_group_ingress_rule" "rdp_from_vpc" {
  security_group_id = aws_security_group.mssql.id
  description       = "RDP from VPC (VPN traffic NATs through VPC ENI)"
  from_port         = 3389
  to_port           = 3389
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr
}

# ─── Inbound: RDP from additional CIDRs (optional) ────
resource "aws_vpc_security_group_ingress_rule" "rdp_extra" {
  for_each = toset(var.allowed_rdp_cidrs)

  security_group_id = aws_security_group.mssql.id
  description       = "RDP from ${each.value}"
  from_port         = 3389
  to_port           = 3389
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

# ─── Outbound: All traffic ─────────────────────────────
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.mssql.id
  description       = "Allow all outbound (Windows Update, SSMS download, S3, etc)"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}


# ─── Additional Rules ─────────────────────────────  REMOVE THIS IF YOU HAVENT CONFIGURED YOUR PROXXY AGENT SECURITY GROUP TO ALLOW INBOUND SQL
#resource "aws_vpc_security_group_ingress_rule" "sql_from_fivetran" {
 # security_group_id            = aws_security_group.mssql.id
 # description                  = "SQL Server from Fivetran Proxy Agent"
 # from_port                    = 1433
 # to_port                      = 1433
 # ip_protocol                  = "tcp"
 # referenced_security_group_id = "sg-0b01a4a2829f8c5c1"
#}