data "aws_ami" "web-ami" {
  most_recent = true

  name_regex = "^web-([0-9_-]+)"
  owners = [
    "self"]
}

resource "aws_iam_instance_profile" "ec2-web" {
  name = "${aws_iam_role.ec2-web.name}"
  role = "${aws_iam_role.ec2-web.name}"
}

resource "aws_autoscaling_group" "web" {
  health_check_grace_period = 300
  health_check_type = "EC2"
  launch_configuration = "${aws_launch_configuration.web.name}"
  max_size = 1
  min_size = 1
  name = "example-${aws_launch_configuration.web.name}"
  termination_policies = [
    "OldestLaunchConfiguration"]
  wait_for_capacity_timeout = "10m"
  metrics_granularity = "1Minute"
  target_group_arns = [
    "${aws_lb_target_group.web.arn}"]
  vpc_zone_identifier = [
    "${data.aws_subnet_ids.default.ids[0]}",
    "${data.aws_subnet_ids.default.ids[1]}",
    "${data.aws_subnet_ids.default.ids[2]}"]
  min_elb_capacity = 1

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key = "ami"
    propagate_at_launch = true
    value = "${data.aws_ami.web-ami.name}"
  }
}

resource "aws_launch_configuration" "web" {
  image_id = "${data.aws_ami.web-ami.id}"
  instance_type = "t2.micro"
  iam_instance_profile = "${aws_iam_instance_profile.ec2-web.name}"
  security_groups = [
    "${aws_security_group.ec2.id}",
    "${aws_security_group.ec2-web.id}"]
  enable_monitoring = false
  ebs_optimized = false
  associate_public_ip_address = false

  user_data = <<DATA
#!/bin/bash

# Shouldn't be present but just in case AMI has got weird
rm /tmp/pull-deploy-last-timestamp*

instanceId=$(curl -sv http://169.254.169.254/latest/meta-data/instance-id)
echo "For instance $instanceId"

eipId=$(aws ec2 --region ${var.aws_region} describe-addresses --filters '[{"Name":"tag:Name","Values":["static-ips-*"]}]' --query 'Addresses[?AssociationId==null]' | jq --raw-output '.[0].AllocationId')

if [ -n "$eipId" ] && [ "$eipId"!="null" ]; then
  echo "Allocating EIP '$eipId'"
  aws ec2 --region ${var.aws_region} associate-address --allocation-id "$eipId" --instance-id "$instanceId"
else
  echo "No EIP found"
fi

# Download deployment tool
deploy_tool_dir="/opt/pull-deploy"
echo "Downloading deployment tool to $deploy_tool_dir"
cd /tmp
rm -f *.tar.gz
wget "https://github.com/M1ke/aws-s3-pull-deploy/archive/0.11.tar.gz"
mkdir -p "$deploy_tool_dir"
echo "Extracting deployment tool"
tar -C "$deploy_tool_dir" -xzf *.tar.gz
mv /opt/pull-deploy/*/* /opt/pull-deploy/

# Download the config
echo "Download deploy config"
aws s3 cp s3://${var.s3-deploy}/config.yml "$deploy_tool_dir/"

# Mount our storage and distributed lock EFS drive
echo "Creating EFS mount point for ${aws_efs_file_system.example.id}"
mkdir -p /efs
sudo mount -t efs ${aws_efs_file_system.example.id}:/ /efs

# Ensure the lock directory exists
mkdir -p /efs/deploy

# This puts the config into the log which is helpful
echo "Show deployment config"
python3 "$deploy_tool_dir/pull-deploy.py" --show
# This runs a deploy
mkdir -p /var/www
python3 "$deploy_tool_dir/pull-deploy.py" --pull
sed -i 's/\/var\/www\/html/\/var\/www\/${var.domain}\/active/' /etc/apache2/sites-available/000-default.conf
sed -i 's/\/var\/www\/html/\/var\/www\/${var.domain}\/active/' /etc/apache2/sites-available/default-ssl.conf
service apache2 restart

mkdir -p /opt/aws/
echo "${aws_db_instance.example.endpoint}" > /opt/aws/rds-endpoint

mkdir -p /var/log/cron/root
crontab <<EOF
# m h  dom mon dow   command
* * * * * python3 "$deploy_tool_dir/pull-deploy.py" --pull >> /var/log/cron/root/deploy
EOF
DATA

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    "aws_efs_file_system.example",
    "aws_cloudwatch_log_group.ec2-init"]

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
    delete_on_termination = true
  }
}
