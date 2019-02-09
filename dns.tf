resource "aws_route53_record" "example-load-balancer-A" {
  zone_id = "${var.zone_id}"
  name = "${var.domain}"
  type = "A"

  alias {
    name = "${aws_lb.example.dns_name}"
    zone_id = "${aws_lb.example.zone_id}"
    evaluate_target_health = false
  }

  provider = "aws.aws-m1ke"
}
