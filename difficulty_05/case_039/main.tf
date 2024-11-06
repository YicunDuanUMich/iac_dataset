terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "test_role8" {
  name = "test_role8"

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

  tags = {
    tag-key = "test_role8"
  }
}

resource "aws_s3_bucket" "apriltwentyninth" {
  bucket = "apriltwentyninth"
}

resource "aws_s3_bucket" "apriltwentyninth2" {
  bucket = "apriltwentyninth2"
}


resource "aws_codebuild_project" "example7" {
  name          = "test-project8"
  service_role  = aws_iam_role.test_role8.arn

  artifacts {
    location  = aws_s3_bucket.apriltwentyninth.bucket
    type      = "S3"
    path      = "/"
    packaging = "ZIP"
  }

  secondary_artifacts {
    artifact_identifier =  "SecondaryArtifact"
    type = "S3"
    location  = aws_s3_bucket.apriltwentyninth2.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/neilbalch/SimplePythonTutorial.git"
    git_clone_depth = 1
  }

}