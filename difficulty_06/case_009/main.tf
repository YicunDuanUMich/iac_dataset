terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.75"
    }
  }

  required_version = "~> 1.9.8"
}


provider "aws" {
  region = "us-east-1" 
  profile = "admin-1"

  assume_role {
    role_arn = "arn:aws:iam::590184057477:role/yicun-iac"
  }
}


resource "aws_iam_role" "eb_ec2_role" {
  name = "elastic_beanstalk_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
      },
    ]
  })
}

# Attach the AWS managed policy for Elastic Beanstalk to the role
resource "aws_iam_role_policy_attachment" "eb_managed_policy" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}


# Create an instance profile tied to the role
resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "elastic_beanstalk_ec2_profile"
  role = aws_iam_role.eb_ec2_role.name
}


resource "aws_s3_bucket" "sample_bucket" {
  bucket_prefix = "sample-"
}

resource "aws_s3_object" "examplebucket_object" {
  key    = "randofile"
  bucket = aws_s3_bucket.sample_bucket.id
  source = "./supplement/app.zip"
}

# Define the Elastic Beanstalk application
resource "aws_elastic_beanstalk_application" "batch_job_app" {
  name        = "batch-job-application"
}

# Define the Elastic Beanstalk application version
resource "aws_elastic_beanstalk_application_version" "version" {
  name        = "batch-job-app-version"
  application = aws_elastic_beanstalk_application.batch_job_app.name
  bucket = aws_s3_object.examplebucket_object.bucket
  key    = aws_s3_object.examplebucket_object.key
}

# Create an Elastic Beanstalk environment in the worker tier
resource "aws_elastic_beanstalk_environment" "batch_job_env" {
  name                = "batch-job-environment"
  application         = aws_elastic_beanstalk_application.batch_job_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.3.0 running Python 3.9"
  tier                = "Worker"
  version_label       = aws_elastic_beanstalk_application_version.version.name

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance" 
  }

  setting {
    namespace = "aws:elasticbeanstalk:sqsd"
    name      = "WorkerQueueURL"
    value     = aws_sqs_queue.batch_job_queue.id 
  }

  setting {
    namespace = "aws:elasticbeanstalk:sqsd"
    name      = "HttpPath"
    value     = "/"
  }

  setting {
    namespace = "aws:elasticbeanstalk:sqsd"
    name      = "MimeType"
    value     = "application/json" 
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }
}

# Define the SQS queue
resource "aws_sqs_queue" "batch_job_queue" {
  name = "batch-job-queue"
}
