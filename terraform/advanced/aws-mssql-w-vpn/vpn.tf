# ═══════════════════════════════════════════════════════
# AWS Client VPN — mutual certificate authentication
# ═══════════════════════════════════════════════════════

# ─── Certificate Authority ─────────────────────────────
resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name  = "${var.project_name}-ca"
    organization = "Eftsure Dev"
  }

  validity_period_hours = 87600
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
}

# ─── Server Certificate (with DNS name for AWS VPN) ────
resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "server" {
  private_key_pem = tls_private_key.server.private_key_pem

  subject {
    common_name  = "vpn.${var.project_name}.internal"
    organization = "Eftsure Dev"
  }

  dns_names = ["vpn.${var.project_name}.internal"]
}

resource "tls_locally_signed_cert" "server" {
  cert_request_pem   = tls_cert_request.server.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 87600

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
}

# ─── Client Certificate ───────────────────────────────
resource "tls_private_key" "client" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "client" {
  private_key_pem = tls_private_key.client.private_key_pem

  subject {
    common_name  = "${var.project_name}-vpn-client"
    organization = "Eftsure Dev"
  }
}

resource "tls_locally_signed_cert" "client" {
  cert_request_pem   = tls_cert_request.client.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 87600

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "client_auth",
  ]
}

# ─── Import Certs to ACM ──────────────────────────────
resource "aws_acm_certificate" "vpn_server" {
  private_key       = tls_private_key.server.private_key_pem
  certificate_body  = tls_locally_signed_cert.server.cert_pem
  certificate_chain = tls_self_signed_cert.ca.cert_pem

  tags = { Name = "${var.project_name}-vpn-server-cert" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "vpn_ca" {
  private_key       = tls_private_key.ca.private_key_pem
  certificate_body  = tls_self_signed_cert.ca.cert_pem

  tags = { Name = "${var.project_name}-vpn-ca-cert" }

  lifecycle {
    create_before_destroy = true
  }
}

# ─── CloudWatch Log Group for VPN ─────────────────────
resource "aws_cloudwatch_log_group" "vpn" {
  name              = "/aws/vpn/${var.project_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_stream" "vpn" {
  name           = "connection-log"
  log_group_name = aws_cloudwatch_log_group.vpn.name
}

# ─── Client VPN Endpoint ──────────────────────────────
resource "aws_ec2_client_vpn_endpoint" "main" {
  description            = "${var.project_name} dev VPN"
  client_cidr_block      = var.vpn_client_cidr
  server_certificate_arn = aws_acm_certificate.vpn_server.arn
  split_tunnel           = true
  transport_protocol     = "udp"
  vpn_port               = 443

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.vpn_ca.arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.vpn.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.vpn.name
  }

  tags = { Name = "${var.project_name}-vpn" }
}

# ─── Associate VPN with private subnet ─────────────────
resource "aws_ec2_client_vpn_network_association" "private" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
  subnet_id              = aws_subnet.private.id
}

# ─── Authorize VPN clients to access entire VPC ───────
resource "aws_ec2_client_vpn_authorization_rule" "vpc" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
  target_network_cidr    = var.vpc_cidr
  authorize_all_groups   = true
  description            = "Allow VPN clients to access VPC"
}

# ─── Export client config + certs as local files ───────
resource "local_file" "client_cert" {
  content  = tls_locally_signed_cert.client.cert_pem
  filename = "${path.module}/vpn-config/client-cert.pem"
}

resource "local_file" "client_key" {
  content  = tls_private_key.client.private_key_pem
  filename = "${path.module}/vpn-config/client-key.pem"
}

resource "local_file" "ca_cert" {
  content  = tls_self_signed_cert.ca.cert_pem
  filename = "${path.module}/vpn-config/ca-cert.pem"
}
