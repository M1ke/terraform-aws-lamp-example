#!/usr/bin/env bash

# Ensure we drop out on a failed build
set -e

# Add any repositories here so we don't have to repeatedly apt update
sudo add-apt-repository ppa:ondrej/php
sudo add-apt-repository 'deb http://archive.ubuntu.com/ubuntu trusty universe'

sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt -yq upgrade

sudo sh -c "echo 'Europe/London' > /etc/timezone"
sudo dpkg-reconfigure -f noninteractive tzdata

# Used in various places
DEBIAN_FRONTEND=noninteractive sudo apt install -yq build-essential software-properties-common binutils git make tree jq php7.2 php7.2-json php7.2-mysql php7.2-dev php7.2-curl mysql-client-5.6 libmysqlclient-dev libapache2-mod-php7.2 python python3 python3-pip

# AWS CLI
sudo pip3 install awscli
sudo pip3 install boto3

# Install cloudwatch logs
sudo rm "/var/log/cloud-init-output.log"
awslogs_file="/tmp/awslogs-agent-setup.py"
wget -O "$awslogs_file" "https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py"
chmod +x "$awslogs_file"
sudo "$awslogs_file" -n -r eu-west-1 -c "/tmp/awslogs.conf"

# Install EFS mount helper
cd /tmp
git clone https://github.com/aws/efs-utils
cd efs-utils
./build-deb.sh
sudo apt-get -y install ./build/amazon-efs-utils*deb

# Systems manager
sudo snap refresh amazon-ssm-agent --classic
sudo snap services amazon-ssm-agent

file_config="/tmp/aws.config"
sudo mkdir -p /root/.aws /home/ssm-user/.aws
sudo cp "$file_config" /root/.aws/config
sudo cp "$file_config" /home/ssm-user/.aws/config
sudo chmod 664 /home/ssm-user/.aws/config
rm "$file_config"

sudo a2enmod ssl
sudo a2ensite default-ssl.conf
sudo service apache2 restart

cd ~

sudo apt autoremove
sudo apt clean
