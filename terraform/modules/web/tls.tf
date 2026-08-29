# tls.tf - Create and import the self-signed TLS certificate

# References:
# Terraform TLS provider private key
# Terraform TLS provider self-signed certificate
# Terraform AWS provider ACM certificate
# AWS Application Load Balancer certificates

resource "tls_private_key" "alb" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "alb" {
  private_key_pem = tls_private_key.alb.private_key_pem

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = [
    aws_lb.web.dns_name,
  ]

  subject {
    common_name  = aws_lb.web.dns_name
    organization = "Engineering Challenge"
  }
}

resource "aws_acm_certificate" "alb" {
  private_key      = tls_private_key.alb.private_key_pem
  certificate_body = tls_self_signed_cert.alb.cert_pem

  tags = {
    Name = "${var.resource_prefix}-cert-alb"
  }
}
