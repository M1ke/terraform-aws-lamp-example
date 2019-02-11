provider "aws" {
  region = "${var.aws_region}"
  version = "~> 1.7"

  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

provider "aws" {
  region = "eu-west-1"
  version = "~> 1.7"

  alias = "aws-m1ke"

  access_key = "${var.m1ke_access_key}"
  secret_key = "${var.m1ke_secret_key}"
}

output "visit-your-website" {
  value = "https://${var.domain}"
}

output "db-endpoint" {
  value = "${aws_db_instance.example.endpoint}"
}

output "static-ips" {
  value = "${aws_eip.static-ips-1.public_ip}, ${aws_eip.static-ips-2.public_ip}"
}
