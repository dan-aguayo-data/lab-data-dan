# ─── Networking ────────────────────────────────────────
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_id" {
  description = "Private subnet where EC2 lives"
  value       = aws_subnet.private.id
}

# ─── EC2 ───────────────────────────────────────────────
output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.mssql.id
}

output "ec2_private_ip" {
  description = "Private IP — use this to connect via SSMS after VPN"
  value       = aws_instance.mssql.private_ip
}

output "ec2_ami_used" {
  description = "AMI used for the EC2 instance"
  value       = local.sql_server_ami
}

# ─── VPN ───────────────────────────────────────────────
output "vpn_endpoint_id" {
  description = "Client VPN endpoint ID"
  value       = aws_ec2_client_vpn_endpoint.main.id
}

output "vpn_dns_name" {
  description = "VPN endpoint DNS name"
  value       = aws_ec2_client_vpn_endpoint.main.dns_name
}

# ─── Connection Instructions ───────────────────────────
output "connection_instructions" {
  description = "How to connect"
  value       = <<-EOT

    ╔══════════════════════════════════════════════════════╗
    ║  DEV MSSQL CONNECTION GUIDE                         ║
    ╠══════════════════════════════════════════════════════╣
    ║                                                      ║
    ║  1. Download VPN config:                             ║
    ║     aws ec2 export-client-vpn-client-configuration \ ║
    ║       --client-vpn-endpoint-id ${aws_ec2_client_vpn_endpoint.main.id} \    ║
    ║       --output text > vpn-config/client-config.ovpn  ║
    ║                                                      ║
    ║  2. Append certs to .ovpn file (see README)          ║
    ║                                                      ║
    ║  3. Import .ovpn into AWS VPN Client or OpenVPN      ║
    ║                                                      ║
    ║  4. Connect VPN, then:                               ║
    ║     - RDP:  ${aws_instance.mssql.private_ip}:3389              ║
    ║     - SSMS: ${aws_instance.mssql.private_ip},1433              ║
    ║     - SA login with your configured password         ║
    ║                                                      ║
    ╚══════════════════════════════════════════════════════╝
  EOT
}

# ─── Security (sensitive) ─────────────────────────────
output "ec2_key_pair_name" {
  description = "Key pair name (for RDP password decryption)"
  value       = aws_key_pair.ec2.key_name
}

output "windows_password_command" {
  description = "Command to get Windows Administrator password"
  value       = "aws ec2 get-password-data --instance-id ${aws_instance.mssql.id} --priv-launch-key vpn-config/${var.project_name}-key.pem"
}
