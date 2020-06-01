resource "aws_lb" "scalr_lb" {
  name            = "${var.name_prefix}-scalr-lb"
  subnets         = data.aws_subnet_ids.scalr_ids.ids
  security_groups = [ data.aws_security_group.default_sg.id, aws_security_group.scalr_sg.id]
  internal        = false
  tags = {
    Name    = "${var.name_prefix}-scalr-lb"
  }
}

resource "aws_lb_target_group" "scalr_lb_target_group" {
  name     = "${var.name_prefix}-scalr-lb-tg"
  port     = "443"
  protocol = "HTTPS"
  vpc_id   = var.vpc
  tags = {
    name = "${var.name_prefix}-scalr-lb-tg"
  }
}

resource "tls_private_key" "scalr_pk" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "scalr_cert" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.scalr_pk.private_key_pem

  subject {
    common_name  = aws_lb.scalr_lb.dns_name
    organization = "Scalr"
  }

  validity_period_hours = 48

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "scalr_iacp_acm_cert" {
  private_key      = tls_private_key.scalr_pk.private_key_pem
  certificate_body = tls_self_signed_cert.scalr_cert.cert_pem
}

resource "aws_lb_listener" "scalr_lb_listener" {
  load_balancer_arn = aws_lb.scalr_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.scalr_iacp_acm_cert.arn

  default_action {
    target_group_arn = aws_lb_target_group.scalr_lb_target_group.arn
    type             = "forward"
  }
}

resource "aws_lb_listener_rule" "listener_rule" {
#  depends_on   = ["aws_lb_target_group.scalr_lb_target_group"]
  listener_arn = aws_lb_listener.scalr_lb_listener.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.scalr_lb_target_group.id
  }
  condition {
    path_pattern {
      values = ["${aws_lb.scalr_lb.dns_name}/*"]
    }
  }
}

resource "aws_lb_target_group_attachment" "scalr_tg_attachment" {
  target_group_arn = aws_lb_target_group.scalr_lb_target_group.arn
  target_id        = aws_instance.iacp_server.0.id
  port             = 443
}