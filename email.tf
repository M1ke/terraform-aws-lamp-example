/* We can't use this in the workshop because you need to manually approve the domain
 via support to send to unverified addresses, which makes it kind of useless

resource "aws_ses_domain_identity" "deploy-notify" {
  domain = "${var.domain}"
}

resource "aws_route53_record" "deploy-notify-ses-verification" {
  zone_id = "${var.zone_id}"
  name    = "_amazonses.${aws_ses_domain_identity.deploy-notify.id}"
  type    = "TXT"
  ttl     = "600"
  records = ["${aws_ses_domain_identity.deploy-notify.verification_token}"]
}

resource "aws_ses_domain_identity_verification" "deploy-notify-ses-verification" {
  domain = "${aws_ses_domain_identity.deploy-notify.id}"

  depends_on = ["aws_route53_record.deploy-notify-ses-verification"]
}

*/
