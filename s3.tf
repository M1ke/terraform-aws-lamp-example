resource "aws_s3_bucket" "elb-logs" {
  bucket = var.s3-load-balancer-logs

  tags = {
    Name = "Logs for load balancers"
  }
}

resource "aws_s3_bucket_acl" "elb-logs" {
  bucket = aws_s3_bucket.elb-logs.bucket
  acl = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "elb-logs" {
  bucket = aws_s3_bucket.elb-logs.bucket

  rule {
    id = "logs-90-day-expiry"
    status = "Enabled"
    filter {
      prefix = "example/AWSLogs/"
    }
    expiration {
      days = 90
    }
  }
}

data "aws_iam_policy_document" "elb-logs" {
  statement {
    effect    = "Allow"
    resources = ["${aws_s3_bucket.elb-logs.arn}/example/AWSLogs/${var.aws_id}/*"]
    actions   = ["s3:PutObject"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::156460612806:root"]
    }
  }
}

resource "aws_s3_bucket_policy" "elb-logs" {
  bucket = aws_s3_bucket.elb-logs.id
  policy = data.aws_iam_policy_document.elb-logs.json
}

resource "aws_s3_bucket" "deploy" {
  bucket = var.s3-deploy

  tags = {
    Name = "Application deployment"
  }
}

resource "aws_s3_bucket_acl" "deploy" {
  bucket = aws_s3_bucket.deploy.bucket
  acl = "private"
}
