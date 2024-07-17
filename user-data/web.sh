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

# Mount our storage and distributed lock EFS drive
echo "Creating EFS mount point for ${efs_id}"
mkdir -p /efs
sudo mount -t efs ${efs_id}:/ /efs

# This puts the config into the log which is helpful
echo "Show deployment config"
sudo chown www-data: "/var/www"
dir="/var/www/${domain}/active"
sudo -u www-data mkdir -p "$dir"
echo '<p>Hello world</p>' > "$dir/index.html"
sed -i 's/\/var\/www\/html/\/var\/www\/${domain}\/active/' /etc/apache2/sites-available/000-default.conf
sed -i 's/\/var\/www\/html/\/var\/www\/${domain}\/active/' /etc/apache2/sites-available/default-ssl.conf
service apache2 restart

mkdir -p /opt/aws/
echo "${aws_db_endpoint}" > /opt/aws/rds-endpoint
