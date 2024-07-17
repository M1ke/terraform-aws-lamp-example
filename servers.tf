data "aws_ami" "web-ami" {
  most_recent = true

  name_regex = "^web-([0-9_-]+)"
  owners = [
    "self"]
}

resource "aws_iam_instance_profile" "ec2-web" {
  name = aws_iam_role.ec2-web.name
  role = aws_iam_role.ec2-web.name
}

resource "aws_launch_template" "web" {
  image_id = data.aws_ami.web-ami.id
  instance_type = "t3.micro"
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2-web.name
  }

  monitoring {
    enabled = false
  }

  vpc_security_group_ids = [
    aws_security_group.ec2.id,
    aws_security_group.ec2-web.id]

  user_data = base64encode(templatefile("${path.module}/user-data/web.sh", {
    aws_region = var.aws_region
    s3_deploy = aws_s3_bucket.deploy.bucket
    efs_id = aws_efs_file_system.example.id
    aws_db_endpoint = aws_db_instance.example.endpoint
    domain = var.domain
  }))

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_type = "gp3"
      volume_size = 12
      delete_on_termination = true
    }
  }
}

resource "aws_autoscaling_group" "web" {
  health_check_grace_period = 300
  health_check_type = "EC2"
  launch_configuration = aws_launch_template.web.name
  max_size = 1
  min_size = 1
  name = "example-${aws_launch_template.web.name}"
  termination_policies = [
    "OldestLaunchConfiguration"]
  wait_for_capacity_timeout = "10m"
  metrics_granularity = "1Minute"
  target_group_arns = [
    aws_lb_target_group.web.arn
  ]
  vpc_zone_identifier = toset(data.aws_subnets.default.id)
  min_elb_capacity = 1

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key = "ami"
    propagate_at_launch = true
    value = data.aws_ami.web-ami.name
  }
}
