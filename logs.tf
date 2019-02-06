resource "aws_cloudwatch_log_group" "ec2-init" {
  name = "/ec2/init"
  retention_in_days = 7
}

output "run-to-view-logs" {
  value = "Run to view logs: awslogs get ${aws_cloudwatch_log_group.ec2-init.name} ALL --watch"
}
