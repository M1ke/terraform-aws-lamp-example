resource "aws_s3_bucket" "elb-logs" {
  bucket = "${var.s3-load-balancer-logs}"
  acl = "private"

  lifecycle_rule {
    id = "logs-90-day-expiry"
    enabled = false
    prefix = "example/AWSLogs/"

    expiration {
      days = 90
    }
  }

  tags {
    Name = "Logs for load balancers"
  }
}

resource "aws_s3_bucket_policy" "elb-logs" {
  bucket = "${aws_s3_bucket.elb-logs.id}"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "AWSConsole-AccessLogs-Policy-1513845670646",
  "Statement": [
    {
      "Sid": "AWSConsoleStmt-1513845670646",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::156460612806:root"
      },
      "Action": "s3:PutObject",
      "Resource": [
        "${aws_s3_bucket.elb-logs.arn}/example/AWSLogs/${var.aws_id}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_s3_bucket" "deploy" {
  bucket = "${var.s3-deploy}"
  acl = "private"

  tags {
    Name = "Application deployment"
  }
}
