resource "aws_cloudwatch_log_group" "ec2-init" {
  name = "/ec2/init"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "web-errors" {
  name = "/web/errors"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "ec2-deploys" {
  name = "/ec2/deploys"
  retention_in_days = 3
}

