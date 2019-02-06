resource "aws_lb" "example" {
  idle_timeout = 60
  internal = false
  name = "example"
  security_groups = [
    "${aws_security_group.web.id}"]
  subnets = ["${data.aws_subnet_ids.default.ids[0]}",
    "${data.aws_subnet_ids.default.ids[1]}",
    "${data.aws_subnet_ids.default.ids[2]}"]

  # Good idea to enable this once you are running a production website
  #  To delete, first change this to 'false' and apply, then destroy
  enable_deletion_protection = false

  access_logs {
    bucket = "${aws_s3_bucket.elb-logs.bucket}"
    enabled = true
    prefix = "example"
  }

  tags {
  }
}

resource "aws_lb_target_group" "web" {
  name = "example"
  port = 443
  protocol = "HTTPS"
  vpc_id = "${var.vpc_id}"
  deregistration_delay = 60

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    protocol = "HTTP"
    path = "/aws-health-check"
    port = 80
    healthy_threshold = 2
    unhealthy_threshold = 3
    timeout = 20
    interval = 40
    matcher = "200-299"
  }

  tags {
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = "${aws_lb.example.arn}"
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = "${aws_acm_certificate.default.arn}"

  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.web.arn}"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = "${aws_lb.example.arn}"
  port = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
