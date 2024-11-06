provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "role" {
  name = "Kendra-Role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "kendra.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "policy" {
  name = "Kendra-Policy"
  role = aws_iam_role.role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_kendra_index" "example" {
  name     = "example"
  role_arn = aws_iam_role.role.arn

  user_group_resolution_configuration {
    user_group_resolution_mode = "AWS_SSO"
  }
}