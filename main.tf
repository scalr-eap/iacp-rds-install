#terraform {
#  backend "remote" {
#    hostname = "my.scalr.com"
#    organization = "org-sfgari365m7sck0"
#    workspaces {
#      name = "iacp-ha-install"
#    }
#  }
#}


locals {
  ssh_private_key_file = "./ssh/id_rsa"
  license_file         = "./license/license.json"
  ssl_cert_file        = "./cert/my.crt"
  ssl_key_file         = "./cert/my.key"
}

provider "aws" {
    region     = var.region
}

#---------------
# Process the license, SSH key, and cert files
#
# These must supplied by input variables when the template is used via Scalr Next-Gen Service Catalog because user has no mechanism to provide them via a file.
# With CLI runs (remote or local) user can provide the key and license in a file.
# File names are set in local values (./ssh/id_rsa and ./license/license.json)
# Variables are ssh_private_key and license which have default value of "FROM_FILE"
# Code below will write the contents of the variables to their respective files if they are not set to "FROM_FILE"

# SSH Key
# This inelegant code takes the SSH private key from the variable and turns it back into a properly formatted key with line breaks

resource "local_file" "ssh_key" {
  count    = var.ssh_private_key == "FROM_FILE" ? 0 : 1
  content  = var.ssh_private_key
  filename = "./ssh/temp_key"
}

resource "null_resource" "fix_key" {
  count      = var.ssh_private_key == "FROM_FILE" ? 0 : 1
  depends_on = [local_file.ssh_key]
  provisioner "local-exec" {
    command = "(HF=$(cat ./ssh/temp_key | cut -d' ' -f2-4);echo '-----BEGIN '$HF;cat ./ssh/temp_key | sed -e 's/--.*-- //' -e 's/--.*--//' | awk '{for (i = 1; i <= NF; i++) print $i}';echo '-----END '$HF) > ${local.ssh_private_key_file}"
  }
}

# license

resource "local_file" "license_file" {
  count      = var.license == "FROM_FILE" ? 0 : 1
  content    = var.license
  filename   = local.license_file
}

# SSL cert

resource "local_file" "ssl_cert" {
  count    = var.ssl_cert == "FROM_FILE" ? 0 : 1
  content  = var.ssl_cert
  filename = "./cert/temp_my.crt"
}

resource "null_resource" "fix_ssl_cert" {
  count      = var.ssl_cert == "FROM_FILE" ? 0 : 1
  depends_on = [local_file.ssl_cert]
  provisioner "local-exec" {
    command = "(HF=$(cat ./cert/temp_my.crt | cut -d' ' -f2-4);echo '-----BEGIN '$HF;cat ./cert/temp_my.crt | sed -e 's/--.*-- //' -e 's/--.*--//' | awk '{for (i = 1; i <= NF; i++) print $i}';echo '-----END '$HF) > ${local.ssl_cert_file}"
  }
}

# SSL key

resource "local_file" "ssl_key" {
  count    = var.ssl_key == "FROM_FILE" ? 0 : 1
  content  = var.ssl_key
  filename = "./cert/temp_my.key"
}

resource "null_resource" "fix_ssl_key" {
  count      = var.ssl_cert == "FROM_FILE" ? 0 : 1
  depends_on = [local_file.ssl_key]
  provisioner "local-exec" {
    command = "(HF=$(cat ./cert/temp_my.key | cut -d' ' -f2-4);echo '-----BEGIN '$HF;cat ./cert/temp_my.key | sed -e 's/--.*-- //' -e 's/--.*--//' | awk '{for (i = 1; i <= NF; i++) print $i}';echo '-----END '$HF) > ${local.ssl_key_file}"
  }
}

# Obtain the AMI for the region

data "aws_ami" "the_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_subnet_ids" "scalr_ids" {
  vpc_id = var.vpc
}

###############################
#
# Scalr Server
#

resource "aws_instance" "iacp_server" {
  count                   = var.server_count
  depends_on              = [null_resource.fix_key, local_file.license_file, aws_db_instance.scalr_mysql, aws_lb.scalr_lb ]
  ami                     = data.aws_ami.the_ami.id
  instance_type           = var.instance_type
  key_name                = var.ssh_key_name
  vpc_security_group_ids  = [ data.aws_security_group.default_sg.id, aws_security_group.scalr_sg.id ]
  subnet_id               = element(tolist(data.aws_subnet_ids.scalr_ids.ids),count.index)

  tags = {
    Name = "${var.name_prefix}-iacp-server"
  }

  connection {
        host	= self.public_ip
        type     = "ssh"
        user     = "ubuntu"
        private_key = file(local.ssh_private_key_file)
        timeout  = "20m"
  }

  provisioner "file" {
        source = local.license_file
        destination = "/var/tmp/license.json"
  }

  provisioner "file" {
#        source = local.ssl_cert_file
        content     = tls_self_signed_cert.scalr_cert.cert_pem
        destination = "/var/tmp/my.crt"
  }

 
  provisioner "file" {
#        source = local.ssl_key_file
        content     = tls_private_key.scalr_pk.private_key_pem
        destination = "/var/tmp/my.key"
  }

  provisioner "file" {
      source = "./SCRIPTS/scalr_install.sh"
      destination = "/var/tmp/scalr_install.sh"
  }

}

resource "aws_ebs_volume" "iacp_vol" {
  availability_zone = aws_instance.iacp_server.0.availability_zone
  type = "gp2"
  size = 50
}

resource "aws_volume_attachment" "iacp_attach" {
  device_name = "/dev/sds"
  instance_id = aws_instance.iacp_server.0.id
  volume_id   = aws_ebs_volume.iacp_vol.id
}

resource "null_resource" "null_1" {
  depends_on = [aws_instance.iacp_server]

  connection {
        host	= aws_instance.iacp_server.0.public_ip
        type     = "ssh"
        user     = "ubuntu"
        private_key = file(local.ssh_private_key_file)
        timeout  = "20m"
  }

  provisioner "remote-exec" {
      inline = [
        "chmod +x /var/tmp/scalr_install.sh",
        "sudo /var/tmp/scalr_install.sh '${var.token}' ${aws_volume_attachment.iacp_attach.volume_id} ${aws_lb.scalr_lb.dns_name} ${aws_db_instance.scalr_mysql.address} ${random_password.mysql_pw.result}",
      ]
  }

}

resource "null_resource" "get_info" {

  depends_on = [null_resource.null_1 ]
  connection {
        host	= aws_instance.iacp_server.0.public_ip
        type     = "ssh"
        user     = "ubuntu"
        private_key = file(local.ssh_private_key_file)
        timeout  = "20m"
  }

  provisioner "file" {
      source = "./SCRIPTS/get_pass.sh"
      destination = "/var/tmp/get_pass.sh"

  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /var/tmp/get_pass.sh",
      "sudo /var/tmp/get_pass.sh",
    ]
  }

}

output "dns_name" {
  value = aws_lb.scalr_lb.dns_name
}
output "scalr_iacp_server_public_ip" {
  value = aws_instance.iacp_server.0.public_ip
}
