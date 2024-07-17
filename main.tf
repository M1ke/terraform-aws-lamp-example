provider "aws" {
  region = "eu-west-1"
}

terraform {
  required_providers {
    archive = {
      source = "hashicorp/archive"
    }
    aws = {
      source = "hashicorp/aws"
      version = "~> 4"
    }
    template = {
      source = "hashicorp/template"
    }
  }
  required_version = ">= 1.2"
}



output "visit-your-website" {
  value = "https://${var.domain}"
}

output "db-endpoint" {
  value = aws_db_instance.example.endpoint
}

output "static-ips" {
  value = "${aws_eip.static-ips-1.public_ip}, ${aws_eip.static-ips-2.public_ip}"
}

output "run-to-view-logs" {
  value = "Run to view logs: awslogs get ${aws_cloudwatch_log_group.ec2-init.name} ALL --watch"
}

output "sns-topics" {
  value = "Add these to receive deploy notifications. Success: ${aws_sns_topic.ec2-web-deploy-success.arn}, Error: ${aws_sns_topic.ec2-web-deploy-error.arn}"
}
