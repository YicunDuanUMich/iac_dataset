provider "aws" {
  region = "us-east-1" # Default region
  alias  = "default"
}

provider "aws" {
  region = "us-west-1"
  alias  = "west"
}

provider "aws" {
  region = "eu-central-1"
  alias  = "europe"
}
resource "aws_iam_role" "eb_ec2_role" {
  provider = aws.default
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
  provider = aws.default
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}


# Create an instance profile tied to the role
resource "aws_iam_instance_profile" "eb_ec2_profile" {
  provider = aws.default
  name = "elastic_beanstalk_ec2_profile"
  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_elastic_beanstalk_application" "us_west" {
  provider = aws.west
  name        = "my-global-app"
  description = "A global application deployed in US-West."
}

# US-West Elastic Beanstalk Environment
resource "aws_elastic_beanstalk_environment" "us_west" {
  provider            = aws.west
  name                = "my-global-app-us-west"
  application         = aws_elastic_beanstalk_application.us_west.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.11 running Python 3.11"
        setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }
}

# Elastic Beanstalk Application (EU-Central Region)
resource "aws_elastic_beanstalk_application" "eu_central" {
  provider = aws.europe
  name        = "my-global-app"
  description = "A global application deployed in EU-Central."
}

# EU-Central Elastic Beanstalk Environment
resource "aws_elastic_beanstalk_environment" "eu_central" {
  provider            = aws.europe
  name                = "my-global-app-eu-central"
  application         = aws_elastic_beanstalk_application.eu_central.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.11 running Python 3.11"

          setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }
}

# Route53 Hosted Zone for the domain
resource "aws_route53_zone" "main" {
  provider = aws.default
  name     = "myglobalapp.com"
}

# Geolocation Routing Policy Records for Route 53 to direct traffic based on location
resource "aws_route53_record" "us_west" {
  provider    = aws.default
  zone_id     = aws_route53_zone.main.zone_id
  name        = "west.myglobalapp.com"
  type        = "CNAME"
  ttl         = "60"
  set_identifier = "us-west"
  geolocation_routing_policy {
    continent = "NA"
  }
  records = [
    aws_elastic_beanstalk_environment.us_west.name
  ]
}

resource "aws_route53_record" "eu_central" {
  provider    = aws.default
  zone_id     = aws_route53_zone.main.zone_id
  name        = "central.myglobalapp.com"
  type        = "CNAME"
  ttl         = "60"
  set_identifier = "eu-central"
  geolocation_routing_policy {
    continent = "EU"
  }
  records = [
    aws_elastic_beanstalk_environment.eu_central.name
  ]
}

