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
