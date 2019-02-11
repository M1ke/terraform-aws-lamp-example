resource "aws_sns_topic" "ec2-web-deploy-success" {
  name = "ec2-web-deploy-success"
}

resource "aws_sns_topic" "ec2-web-deploy-error" {
  name = "ec2-web-deploy-error"
}
