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

resource "aws_iam_role" "test_role11" {
  name = "test_role11"

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
    tag-key = "test_role11"
  }
}

resource "aws_s3_bucket" "aprilthirthyfirst" {
  bucket = "aprilthirthyfirst"
}

resource "aws_s3_bucket" "aprilthirthyfirst2" {
  bucket = "aprilthirthyfirst2"
}

resource "aws_codebuild_project" "example11" {
  name          = "test-project11"
  service_role  = aws_iam_role.test_role11.arn

  artifacts {
    location  = aws_s3_bucket.aprilthirthyfirst.bucket
    type      = "S3"
    path      = "/"
    packaging = "ZIP"
  }

  secondary_artifacts {
    artifact_identifier =  "SecondaryArtifact"
    type = "S3"
    location  = aws_s3_bucket.aprilthirthyfirst2.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "SOME_KEY1"
      value = "SOME_VALUE1"
    }

    environment_variable {
      name  = "SOME_KEY2"
      value = "SOME_VALUE2"
      type  = "PARAMETER_STORE"
    }

  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/neilbalch/SimplePythonTutorial.git"
    git_clone_depth = 1
  }

  secondary_sources {
    source_identifier = "SecondarySource"
    type            = "GITHUB"
    location        = "https://github.com/pH-7/Simple-Java-Calculator.git"
    git_clone_depth =  1
  }

}