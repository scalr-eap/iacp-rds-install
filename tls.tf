resource "tls_private_key" "scalr_pk" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "scalr_cert" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.scalr_pk.private_key_pem

  subject {
    common_name  = aws_instance.iacp_server.public_dns
    organization = "Scalr"
  }

  validity_period_hours = 48

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}
