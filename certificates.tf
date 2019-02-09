resource "aws_acm_certificate" "default" {
  domain_name = "${var.domain}"
  validation_method = "DNS"

  tags {
    Name = "${var.domain} certificate"
  }

  subject_alternative_names = []
}

resource "aws_route53_record" "acm-validation" {
  name = "${aws_acm_certificate.default.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.default.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.zone_id}"
  records = ["${aws_acm_certificate.default.domain_validation_options.0.resource_record_value}"]
  ttl = 300

  provider = "aws.aws-m1ke"
}

resource "aws_acm_certificate_validation" "default" {
  certificate_arn = "${aws_acm_certificate.default.arn}"
  validation_record_fqdns = ["${aws_route53_record.acm-validation.fqdn}"]
}
