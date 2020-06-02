# scalr-install
Install and configure Scalr IaCP with Terraform on AWS with an RDS database and ALB load balancer

This template will install Scalr on a single server

This template is configured as follows.

1. Built for AWS - Expects credentials to be provided via Environment Variables
2. Auto selects latest Canonical Ubuntu 16.04 LTS AMI for the chosen region
3. Uses DNS name generated by the ALB
4. Generates self-signed cert for Scalr/ALB using tls_self_signed_cert. You can replace the cert later.

## To run via CLI

1. Pull the repo.
1. Upload your public key to AWS.
1. Copy your Scalr license to ./license/license.json in the repo
1. Copy your private ssh key to ./ssh/id_rsa in the repo
1. Copy your SSL Certificate to ./cert/my.crt
1. Copy your SSL key to ./cert/my.key
1. Set values for the following variables in terraform.tfvars(.json) or provide values on the command line at runtime
1. `region` - AWS Region to use.
1. `key_name` - Key in AWS.
1. `token` - Your packagecloud.io download token supplied with the license.
1. `vpc` - VPC to be used.
1. `instance_type` - Must be 4GB ram. t3.medium recommended.
1. `name_prefix` - 1-3 character prefix to be added to all instance names.
1. Set your access keys for AWS using environment variables `export AWS_ACCESS_KEY_ID=<access_key> AWS_SECRET_ACCESS_KEY=<secret_key>`
1. Run `terraform init;terraform apply` and watch the magic happen.

Note: This represents the baseline configuration. It is up to you to add things like backup policies, autoscaling, etc to the configuration.
