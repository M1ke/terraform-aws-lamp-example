provider "aws" {
  region = "${var.aws_region}"
  version = "~> 1.7"
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
