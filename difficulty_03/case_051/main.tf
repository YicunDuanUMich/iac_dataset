provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "test_rolelex" {
  name = "test_rolelex"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_lexv2models_bot" "example" {
  name = "example"
  data_privacy {
    child_directed = false
  }
  idle_session_ttl_in_seconds = 100
  role_arn                    = aws_iam_role.test_rolelex.arn

  tags = {
    foo = "bar"
  }
}