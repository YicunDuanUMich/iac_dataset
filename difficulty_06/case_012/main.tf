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

# Elastic Beanstalk application
resource "aws_elastic_beanstalk_application" "myapp" {
  name        = "myapp"
  description = "An application for Blue/Green deployment."
}

# Blue environment
resource "aws_elastic_beanstalk_environment" "blue" {
  name                = "${aws_elastic_beanstalk_application.myapp.name}-blue"
  application         = aws_elastic_beanstalk_application.myapp.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.11 running Python 3.11"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }
}

# Green environment (New version)
resource "aws_elastic_beanstalk_environment" "green" {
  name                = "${aws_elastic_beanstalk_application.myapp.name}-green"
  application         = aws_elastic_beanstalk_application.myapp.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.11 running Python 3.11"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }
}

# Route53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = "example53.com"
}

# Weighted DNS records for Blue and Green environments
resource "aws_route53_record" "blue" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "CNAME"
  ttl     = "60"
  weighted_routing_policy {
    weight = 120
  }
  set_identifier = "BlueEnvironment"
  records = [
    aws_elastic_beanstalk_environment.blue.cname
  ]
}

resource "aws_route53_record" "green" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "CNAME"
  ttl     = "60"
  weighted_routing_policy {
    weight = 60
  }
  set_identifier = "GreenEnvironment"
  records = [
    aws_elastic_beanstalk_environment.green.cname
  ]
}