data "aws_subnet_ids" "default" {
  vpc_id = "${var.vpc_id}"
}

resource "aws_security_group" "db" {
  name = "db"
  description = "Allows other servers database access"
  vpc_id = "${var.vpc_id}"

  tags {
    "Name" = "Database internal access"
  }
}
resource "aws_security_group_rule" "db-mysql" {
  type = "ingress"
  from_port = 3306
  to_port = 3306
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.ec2.id}"

  security_group_id = "${aws_security_group.db.id}"
}
resource "aws_security_group_rule" "db-outbound" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = [
    "0.0.0.0/0"]

  security_group_id = "${aws_security_group.db.id}"
}

resource "aws_security_group" "ec2" {
  name = "ec2"
  description = "EC2 instances, allow to connect to internal database and make outbound connections"
  vpc_id = "${var.vpc_id}"

  tags {
    "Name" = "EC2"
  }
}
resource "aws_security_group_rule" "ec2-outbound" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = [
    "0.0.0.0/0"]

  security_group_id = "${aws_security_group.ec2.id}"
}

resource "aws_security_group" "ec2-web" {
  name = "ec-web2"
  description = "EC2 instances, allow to connect to internal database and be connected to from load balancer"
  vpc_id = "${var.vpc_id}"

  tags {
    "Name" = "EC2 Web"
  }
}
resource "aws_security_group_rule" "ec2-web-http-in" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.web.id}"

  security_group_id = "${aws_security_group.ec2-web.id}"
}
resource "aws_security_group_rule" "ec2-web-https-in" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.web.id}"

  security_group_id = "${aws_security_group.ec2-web.id}"
}


resource "aws_security_group" "efs" {
  name = "efs"
  description = "EFS mount"
  vpc_id = "${var.vpc_id}"

  tags {
    "Name" = "EFS access"
  }
}
resource "aws_security_group_rule" "efs-from-ec2" {
  type = "ingress"
  from_port = 2049
  to_port = 2049
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.ec2.id}"

  security_group_id = "${aws_security_group.efs.id}"
}
resource "aws_security_group_rule" "efs-outbound" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = [
    "0.0.0.0/0"]

  security_group_id = "${aws_security_group.efs.id}"
}

resource "aws_security_group" "web" {
  name = "live-web"
  description = "Live 443 and 80 for load balancers"
  vpc_id = "${var.vpc_id}"

  tags {
    "Name" = "Web access"
  }
}
resource "aws_security_group_rule" "web-http" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"]

  security_group_id = "${aws_security_group.web.id}"
}
resource "aws_security_group_rule" "web-https" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"]

  security_group_id = "${aws_security_group.web.id}"
}
resource "aws_security_group_rule" "web-outbound" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = [
    "0.0.0.0/0"]

  security_group_id = "${aws_security_group.web.id}"
}
