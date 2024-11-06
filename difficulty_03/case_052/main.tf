provider "aws" {
  region = "us-west-2"
}
resource "aws_iam_role" "test_rolelex12" {
  name = "test_rolelex12"

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
  description  = "An example bot for child-directed interactions"
  role_arn     = aws_iam_role.test_rolelex12.arn
  type         = "Bot"
  data_privacy {
    child_directed = true
  }
  idle_session_ttl_in_seconds = 100

  tags = {
    foo = "bar"
  }
}