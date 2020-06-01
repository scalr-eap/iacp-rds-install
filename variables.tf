variable "token" {
  description = "Paste in the packagecloud.io token that came with your license file."
  type = string
}

variable "license" {
  description = "Paste in the entire contents of your Scalr license file"
  type = string
  default = "FROM_FILE"
}

variable "ssl_cert" {
  description = "Paste in the entire contents of your SSL certificate"
  type = string
  default = "FROM_FILE"
}

variable "ssl_key" {
  description = "Paste in the entire contents of your SSL key"
  type = string
  default = "FROM_FILE"
}

variable "region" {
  description = "The AWS Region to deploy in"
  type = string
}

variable "instance_type" {
  description = "Instance type must have minimum of 16GB ram and 50GB disk"
  type = string
}

variable "ssh_key_name" {
  description = "The name of then public SSH key to be deployed to the servers. This must exist in AWS already"
  type = string
}

variable "ssh_private_key" {
  description = "The text of SSH Private key. This will be formatted by the Terraform template.<br>This will be used in the remote workspace to allow Terraform to connect to the servers and run scripts to configure Scalr. It only exists in the workspace for the duration of the run."
  type = string
  default = "FROM_FILE"
}

variable "vpc" {
  type = string
  description = "RDS database and ALB will be mapped to all subnets in the VPC. Must be at least 2 subnets in 2 AZ's. Instances will be allocated to subnets in sequence"
}

variable "name_prefix" {
  description = "1-3 char prefix for instance names"
  type = string
}

variable domain_name {
  description = "Domain name for the IaCP system"
  type = string
}

variable "server_count" {
  description = "Number of Scalr servers to start up (Current max=1)"
  type = number
  default = 1
}
