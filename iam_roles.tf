data "aws_iam_policy_document" "ec2-web" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2-web" {
  name               = "ec2-web"
  path               = "/"
  description        = "Allows EC2 instances to call AWS services on your behalf."
  assume_role_policy = data.aws_iam_policy_document.ec2-web.json
}

data "aws_iam_policy_document" "ec2" {
  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]
    actions   = ["cloudwatch:PutMetricData"]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:AssociateAddress",
      "ec2:Describe*",
    ]
  }

  statement {
    sid    = ""
    effect = "Allow"

    resources = [
      aws_s3_bucket.deploy.arn,
      "${aws_s3_bucket.deploy.arn}/*",
    ]

    actions = [
      "s3:GetObject*",
      "s3:ListBucket*",
    ]
  }

  statement {
    sid    = ""
    effect = "Allow"

    resources = [
      aws_sns_topic.ec2-web-deploy-success.arn,
      aws_sns_topic.ec2-web-deploy-error.arn,
    ]

    actions = ["sns:Publish"]
  }
}

resource "aws_iam_policy" "ec2" {
  name   = "ec2"
  policy = data.aws_iam_policy_document.ec2.json
}

resource "aws_iam_role_policy_attachment" "ec2-ec2-web" {
  policy_arn = aws_iam_policy.ec2.arn
  role       = aws_iam_role.ec2-web.name
}

data "aws_iam_policy_document" "ssm-custom" {
  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ssm:DescribeAssociation",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:GetManifest",
      "ssm:GetParameters",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutInventory",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]
    actions   = ["cloudwatch:PutMetricData"]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:DescribeInstanceStatus"]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ds:CreateComputer",
      "ds:DescribeDirectories",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]
  }

  statement {
    sid    = ""
    effect = "Allow"

    resources = [
      "arn:aws:s3:::aws-ssm-us-west-2/*",
      "arn:aws:s3:::aws-windows-downloads-us-west-2/*",
      "arn:aws:s3:::amazon-ssm-packages-us-west-2/*",
      "arn:aws:s3:::us-west-2-birdwatcher-prod/*",
    ]

    actions = [
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetEncryptionConfiguration",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
    ]
  }
}

resource "aws_iam_policy" "ssm-custom" {
  name        = "ssm-custom"
  path        = "/"
  description = "A cut down policy for systems manager removing full S3 access"
  policy      = data.aws_iam_policy_document.ssm-custom.json
}

resource "aws_iam_role_policy_attachment" "ssm-custom-ec2-web" {
  policy_arn = aws_iam_policy.ssm-custom.arn
  role       = aws_iam_role.ec2-web.name
}

