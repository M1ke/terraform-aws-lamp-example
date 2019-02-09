#!/usr/bin/env bash

# Ensure we drop out on a failed build
set -e

echo "[Log] Adding PPAs before we do all the apt calls"
sudo add-apt-repository ppa:ondrej/php
# This lets us get at mysql-5.6 rather than 5.7 which is default on Ubuntu 16.04+
sudo add-apt-repository 'deb http://archive.ubuntu.com/ubuntu trusty universe'

echo "[Log] Running apt update & upgrade"
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt -yq upgrade

echo "[Log] Set timezone"
sudo sh -c "echo 'Europe/London' > /etc/timezone"
sudo dpkg-reconfigure -f noninteractive tzdata

echo "[Log] Install everything we need from apt"
DEBIAN_FRONTEND=noninteractive sudo apt install -yq build-essential software-properties-common binutils git make tree jq php7.2 php7.2-json php7.2-mysql php7.2-dev php7.2-curl mysql-client-5.6 libmysqlclient-dev libapache2-mod-php7.2 python python3 python3-pip

# If you get an error about not being able to find the mysql-client install candidate just try again; have encountered it once, but couldn't work out why and running again fixed it. Potentially some issue loading the "trusty universe" repository above

echo "[Log] Install AWS CLI"
sudo pip3 install awscli
sudo pip3 install boto3

echo "[Log] Install cloudwatch logs"
sudo rm "/var/log/cloud-init-output.log"
awslogs_file="/tmp/awslogs-agent-setup.py"
wget -O "$awslogs_file" "https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py"
chmod +x "$awslogs_file"
sudo "$awslogs_file" -n -r eu-west-1 -c "/tmp/awslogs.conf"

echo "[Log] Installing the EFS mount helper; we use this on instance start"
cd /tmp
git clone https://github.com/aws/efs-utils
cd efs-utils
./build-deb.sh
sudo apt-get -y install ./build/amazon-efs-utils*deb

echo "[Log] Ensure we have the latest AWS systems manager to allow remote shell without SSH"
sudo snap refresh amazon-ssm-agent --classic
sudo snap services amazon-ssm-agent

echo "[Log] Configure root and ssm-user AWS CLI access"
file_config="/tmp/aws.config"
sudo mkdir -p /root/.aws /home/ssm-user/.aws
sudo cp "$file_config" /root/.aws/config
sudo cp "$file_config" /home/ssm-user/.aws/config
sudo chmod 664 /home/ssm-user/.aws/config
rm "$file_config"

echo "[Log] Configure apache"
sudo a2enmod ssl
sudo a2ensite default-ssl.conf
sudo service apache2 restart

echo "[Log] Change back to home in case we get any oddities in directories when the server boots"
cd ~

echo "[Log] Clean up"
sudo apt autoremove
sudo apt clean

echo "[Log] Done!"
