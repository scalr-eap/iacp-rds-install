/*
# Load Balancer
#

resource "aws_elb" "scalr_lb" {
  name               = "${var.name_prefix}-scalr-lb"

  subnets         = [var.subnet]
  security_groups = [ data.aws_security_group.default_sg.id, aws_security_group.scalr_sg.id]
  instances       = [ aws_instance.iacp_server.id ]

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 8080
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 443
    instance_protocol = "http"
    lb_port           = 443
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:8080"
    interval            = 30
  }

  tags = {
    Name = "${var.name_prefix}-scalr-elb"
  }
}
*/
