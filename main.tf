provider "aws" {
  region = "${var.aws_region}"
  version = "~> 1.7"
}

output "visit-your-website" {
  value = "https://${var.domain}"
}
