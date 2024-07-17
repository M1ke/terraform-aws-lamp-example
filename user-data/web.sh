#!/bin/bash

# Shouldn't be present but just in case AMI has got weird
rm /tmp/pull-deploy-last-timestamp*

instanceId=$(curl -sv http://169.254.169.254/latest/meta-data/instance-id)
echo "For instance $instanceId"

eipId=$(aws ec2 --region ${aws_region} describe-addresses --filters '[{"Name":"tag:Name","Values":["static-ips-*"]}]' --query 'Addresses[?AssociationId==null]' | jq --raw-output '.[0].AllocationId')

if [ -n "$eipId" ] && [ "$eipId" != "null" ]; then
  echo "Allocating EIP '$eipId'"
  aws ec2 --region ${aws_region} associate-address --allocation-id "$eipId" --instance-id "$instanceId"
else
  echo "No EIP found"
fi

# Download deployment tool
deploy_tool_dir="/opt/pull-deploy"
echo "Downloading deployment tool to $deploy_tool_dir"
cd "/tmp"
rm -f *.tar.gz
wget "https://github.com/M1ke/aws-s3-pull-deploy/archive/0.11.tar.gz"
mkdir -p "$deploy_tool_dir"
echo "Extracting deployment tool"
tar -C "$deploy_tool_dir" -xzf *.tar.gz
mv /opt/pull-deploy/*/* /opt/pull-deploy/

# Download the config
echo "Download deploy config"
aws s3 cp s3://${s3_deploy}/config.yml "$deploy_tool_dir/"

# Mount our storage and distributed lock EFS drive
echo "Creating EFS mount point for ${efs_id}"
mkdir -p /efs
sudo mount -t efs ${efs_id}:/ /efs

# Ensure the lock directory exists
mkdir -p /efs/deploy

# This puts the config into the log which is helpful
echo "Show deployment config"
python3 "$deploy_tool_dir/pull-deploy.py" --show
# This runs a deploy
mkdir -p /var/www
python3 "$deploy_tool_dir/pull-deploy.py" --pull
sed -i 's/\/var\/www\/html/\/var\/www\/${domain}\/active/' /etc/apache2/sites-available/000-default.conf
sed -i 's/\/var\/www\/html/\/var\/www\/${domain}\/active/' /etc/apache2/sites-available/default-ssl.conf
service apache2 restart

mkdir -p /opt/aws/
echo "${aws_db_endpoint}" > /opt/aws/rds-endpoint

mkdir -p /var/log/cron/root
crontab <<EOF
# m h  dom mon dow   command
* * * * * python3 "$deploy_tool_dir/pull-deploy.py" --pull >> /var/log/cron/root/deploy
EOF
