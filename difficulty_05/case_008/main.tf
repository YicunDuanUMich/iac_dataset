provider "aws" {
  region = "us-east-1" 
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


# Common Elastic Beanstalk application for all microservices
resource "aws_elastic_beanstalk_application" "microservices_app" {
  name        = "microservices-app"
}

# First microservice environment
resource "aws_elastic_beanstalk_environment" "microservice_one_env" {
  name                = "microservice-one"
  application         = aws_elastic_beanstalk_application.microservices_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.9 running Python 3.11"
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "3"
  }

  setting {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "IamInstanceProfile"
      value     = aws_iam_instance_profile.eb_ec2_profile.name
    }
}

# Second microservice environment
resource "aws_elastic_beanstalk_environment" "microservice_two_env" {
  name                = "microservice-two"
  application         = aws_elastic_beanstalk_application.microservices_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.9 running Python 3.11"

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "2"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "4"
  }

    setting {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "IamInstanceProfile"
      value     = aws_iam_instance_profile.eb_ec2_profile.name
    }
}