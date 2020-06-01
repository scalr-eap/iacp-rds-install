resource "random_password" "mysql_pw" {
  length = 41
  special = false
  upper = false
  number = true
}

data "aws_subnet_ids" "scalr" {
  vpc_id = "${var.vpc}"
}

resource "aws_db_subnet_group" "scalr" {
  name = "scalr-db-subnet-group"
  subnet_ids = data.aws_subnet_ids.scalr.ids

  tags = {
    Name = "RDS-Scalr-Group1"
  }
}

resource "aws_db_parameter_group" "default" {
  name   = "rds-scalr"
  family = "mysql5.7"

  parameter {
    name  = "character_set_server"
    value = "utf8"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8"
  }

  parameter {
    name  = "sql_mode"
    value = "STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"
  }
}

resource "aws_db_instance" "scalr_mysql" {
  allocated_storage    = 750
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  multi_az             = true
  instance_class       = "db.t3.xlarge"
  name                 = "scalr"
  username             = "scalr"
  password             = random_password.mysql_pw.result
  db_subnet_group_name = aws_db_subnet_group.scalr.name
  vpc_security_group_ids = [ data.aws_security_group.default_sg.id, aws_security_group.mysql_sg.id, aws_security_group.scalr_sg.id]
  skip_final_snapshot  = true
  parameter_group_name = aws_db_parameter_group.default.name
}

output "db_address" {
  value = aws_db_instance.scalr_mysql.address
}

output rds_creds {
  value = random_password.mysql_pw.result
}
