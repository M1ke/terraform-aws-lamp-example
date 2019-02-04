resource "aws_cloudwatch_log_group" "ec2-init" {
  name = "/ec2/init"
  retention_in_days = 7
}
