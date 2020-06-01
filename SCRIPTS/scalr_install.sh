#!/bin/bash

# Runs as root via sudo

exec 1>/var/tmp/$(basename $0).log

exec 2>&1

abort () {
  echo "ERROR: Failed with $1 executing '$2' @ line $3"
  exit $1
}

trap 'abort $? "$STEP" $LINENO' ERR

TOKEN="${1}"
VOL="${2}"
DOMAIN_NAME="${3}"
DB_HOST="${4}"
MYSQL_PW="${5}"

VOL2=$(echo $VOL | sed 's/-//')
DEVICE=$(lsblk -o NAME,SERIAL | grep ${VOL2} | awk '{print $1}')


STEP="MKFS"
mkfs -t ext4 /dev/${DEVICE}

STEP="mkdir"
mkdir /opt/scalr-server

STEP="mount /opt/scalr-server"
mount /dev/${DEVICE} /opt/scalr-server
echo /dev/${DEVICE}  /opt/scalr-server ext4 defaults,nofail 0 2 >> /etc/fstab


STEP="curl to down load repo"
curl -s https://${TOKEN}:@packagecloud.io/install/repositories/scalr/scalr-server-ee-staging/script.deb.sh | bash

STEP="apt-get install scalr-server"
apt-get install -y scalr-server

STEP="scalr-server-wizard"
scalr-server-wizard

STEP="Set Mysql Password in secrets"
sed 's/"scalr_password": .*,/"scalr_password": "'$MYSQL_PW'",/' /etc/scalr-server/scalr-server-secrets.json > /var/tmp/scalr-server-secrets.json
cp /var/tmp/scalr-server-secrets.json /etc/scalr-server/scalr-server-secrets.json

STEP="Create config with cat"

cat << ! > /etc/scalr-server/scalr-server.rb
enable_all true
product_mode :iacp

mysql[:enable] = false

# Mandatory SSL
# Update the below settings to match your FQDN and where your .key and .crt are stored
proxy[:ssl_enable] = true
proxy[:ssl_redirect] = true
proxy[:ssl_cert_path] = "/etc/scalr-server/organization.crt"
proxy[:ssl_key_path] = "/etc/scalr-server/organization.key"

routing[:endpoint_host] = "$DOMAIN_NAME"
routing[:endpoint_scheme] = "https"

#Add if you have a self signed cert, update with the proper location if needed
#ssl[:extra_ca_file] = "/etc/scalr-server/rootCA.pem"

#Add if you require a proxy, it will be used for http and https requests
#http_proxy "http://user:*****@my.proxy.com:8080"

#If a no proxy setting is needed, you can define a domain or subdomain like so: no_proxy=example.com,domain.com . The following setting would not work: *.domain.com,*example.com
#no_proxy example.com

#If you are using an external database service or separating the database onto a different server.
app[:mysql_scalr_host] = "$DB_HOST"
app[:mysql_scalr_port] = 3306

app[:mysql_analytics_host] = "$DB_HOST"
app[:mysql_analytics_port] = 3306

####The following is only needed if you want to use a specific version of Terraform that Scalr may not included yet.####
#app[:configuration] = {
#:scalr => {
#  "tf_worker" => {
#      "default_terraform_version"=> "0.12.20",
#      "terraform_images" => {
#          "0.12.10" => "hashicorp/terraform:0.12.10",
#          "0.12.20" => "hashicorp/terraform:0.12.20"
#      }
#    }
#  }
#}
!

# Conditional because MySQL Master wont have it's local file yet

STEP="Create License"
cp /var/tmp/license.json /etc/scalr-server/license.json

# Copy cert files if they exist. Only on server, not on Mysql
STEP="SSL Cert"
[[ -f /var/tmp/my.crt ]] && cp /var/tmp/my.crt /etc/scalr-server/organization.crt

STEP="SSL key"
[[ -f /var/tmp/my.key ]] && cp /var/tmp/my.key /etc/scalr-server/organization.key

STEP="Create Analytics Database"
sudo /opt/scalr-server/embedded/bin/mysql -h $DB_HOST -u scalr -p$(sudo sed -n "/mysql/,+2p" /var/tmp/scalr-server-secrets.json | tail -1 | sed 's/.*: "\(.*\)",/\1/') scalr << !
CREATE DATABASE analytics;
!

STEP="scalr-server-ctl reconfigure"
scalr-server-ctl reconfigure

exit 0
