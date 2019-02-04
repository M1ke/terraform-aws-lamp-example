resource "aws_iam_role" "ec2-web" {
  name = "ec2-web"
  path = "/"
  description = "Allows EC2 instances to call AWS services on your behalf."
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "ec2" {
  name = "ec2"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AssociateAddress",
        "ec2:Describe*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject*",
        "s3:ListBucket*"
      ],
      "Resource": [
        "${aws_s3_bucket.deploy.arn}",
        "${aws_s3_bucket.deploy.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ses:SendEmail",
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "ec2" {
  name = "ec2"
  policy_arn = "${aws_iam_policy.ec2.arn}"

  groups = []
  users = []
  roles = ["${aws_iam_role.ec2-web.name}"]
}

resource "aws_iam_policy" "ssm-custom" {
  name = "ssm-custom"
  path = "/"
  description = "A cut down policy for systems manager removing full S3 access"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
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
                "ssm:UpdateInstanceInformation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2messages:AcknowledgeMessage",
                "ec2messages:DeleteMessage",
                "ec2messages:FailMessage",
                "ec2messages:GetEndpoint",
                "ec2messages:GetMessages",
                "ec2messages:SendReply"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstanceStatus"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ds:CreateComputer",
                "ds:DescribeDirectories"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "s3:GetBucketLocation",
            "s3:PutObject",
            "s3:GetObject",
            "s3:GetEncryptionConfiguration",
            "s3:AbortMultipartUpload",
            "s3:ListMultipartUploadParts",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads"
          ],
          "Resource": [
            "arn:aws:s3:::aws-ssm-us-west-2/*",
            "arn:aws:s3:::aws-windows-downloads-us-west-2/*",
            "arn:aws:s3:::amazon-ssm-packages-us-west-2/*",
            "arn:aws:s3:::us-west-2-birdwatcher-prod/*"
          ]
        }
    ]
}
POLICY
}

resource "aws_iam_policy_attachment" "ssm-custom" {
  name = "ssm-custom"
  policy_arn = "${aws_iam_policy.ssm-custom.arn}"

  groups = []
  users = []
  roles = [
    "${aws_iam_role.ec2-web.name}"]
}
