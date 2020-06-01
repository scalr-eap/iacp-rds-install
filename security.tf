## Default SG

data "aws_security_group" "default_sg" {
  name = "default"
  vpc_id = var.vpc
}


###############################
#
# Scalr Security Group

resource "aws_security_group" "scalr_sg" {
  name        = "${var.name_prefix}-scalr_sg"
  description = "General rules for Scalr Servers"
  vpc_id      = var.vpc

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

###############################
#
# MySQL Security Group

resource "aws_security_group" "mysql_sg" {
  name        = "${var.name_prefix}-mysql_sg"
  description = "Used in the terraform"
  vpc_id      = var.vpc

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
