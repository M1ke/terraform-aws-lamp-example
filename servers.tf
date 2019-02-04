data "aws_ami" "web-ami" {
  most_recent = true

  name_regex = "^web-([0-9_-]+)"
  owners = [
    "self"]
}

resource "aws_autoscaling_group" "web" {
  desired_capacity = 1
  health_check_grace_period = 300
  health_check_type = "EC2"
  launch_configuration = "${aws_launch_configuration.web.name}"
  max_size = 2
  min_size = 1
  name = "dev-${aws_launch_configuration.web.name}"
  termination_policies = [
    "OldestLaunchConfiguration"]
  wait_for_capacity_timeout = "10m"
  metrics_granularity = "1Minute"
  target_group_arns = [
    "${aws_lb_target_group.web.arn}"]
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
  iam_instance_profile = "${aws_iam_role.ec2-web.name}"
  security_groups = [
    "${aws_security_group.ec2.id}",
    "${aws_security_group.ec2-web.id}"]
  enable_monitoring = false
  ebs_optimized = false
  user_data = <<DATA
#!/bin/bash

# Shouldn't be present but just in case AMI has got weird
rm /tmp/pull-deploy-last-timestamp*

eipId=$(aws ec2 describe-addresses --filters '[{"Name":"tag:Name","Values":["live-egress-*"]}]' --query 'Addresses[?AssociationId==null]' | jq --raw-output '.[0].AllocationId')
instanceId=$(curl -sv http://169.254.169.254/latest/meta-data/instance-id)

echo "For instance $instanceId"

if [ eipId ]; then
  echo "Allocating EIP $eipId"
  aws ec2 --region ${var.aws_region} associate-address --allocation-id $eipId --instance-id $instanceId
else
  echo "No EIP found"
fi

# Here is where we need to:
# * Pull the deploy tool from github
# * Load the config from S3
# * Run the tool

# Mount our storage and distributed lock EFS drive
mkdir -p /efs
sudo mount -t efs $${aws_efs_file_system.example.id}:/ /efs

# Download deployment tool
deploy_tool_dir="/opt/pull-deploy"
cd /tmp
rm -f *.tar.gz
curl -s https://api.github.com/repos/m1ke/aws-s3-pull-deploy/releases/latest \
  | jq '.assets[0].browser_download_url' --raw-output \
  | wget -qi -
tar -C "$deploy_tool_dir" -xzf *.tar.gz
mkdir -p "$deploy_tool_dir"
aws s3 cp s3://$${var.s3-deploy}/config.yml "$deploy_tool_dir/"
mkdir -p /efs/deploy

# This puts the config into the log which is helpful
python3 "$deploy_tool_dir/pull-deploy.py" --show
# This runs a deploy
mkdir -p /var/www
python3 "$deploy_tool_dir/pull-deploy.py" --pull

crontab /efs/cron/root-cron
DATA

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
    delete_on_termination = true
  }
}
