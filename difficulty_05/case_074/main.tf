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
  name        = "example"
  description = "example"
  edition     = "DEVELOPER_EDITION"
  role_arn    = aws_iam_role.role.arn
}

resource "aws_kendra_data_source" "example" {
  index_id = aws_kendra_index.example.id
  name     = "example"
  type     = "WEBCRAWLER"
  role_arn = aws_iam_role.role.arn

  configuration {
    web_crawler_configuration {
      proxy_configuration {
        host        = "a.example.com"
        port        = "443"
      }

      urls {
        seed_url_configuration {
          seed_urls = [
            "https://docs.aws.amazon.com/codedeploy/latest/userguide/getting-started-create-service-role.html"
          ]
        }
      }
    }
  }
}