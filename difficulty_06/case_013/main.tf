terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.75"

      configuration_aliases = [ aws.default, aws.west, aws.europe ]
    }
  }

  required_version = "~> 1.9.8"
}

provider "aws" {
  region = "us-east-1" # Default region
  alias  = "default"

  profile = "admin-1"

  assume_role {
    role_arn = "arn:aws:iam::590184057477:role/yicun-iac"
  }
}

provider "aws" {
  region = "us-west-1"
  alias  = "west"

  profile = "admin-1"

  assume_role {
    role_arn = "arn:aws:iam::590184057477:role/yicun-iac"
  }
}

provider "aws" {
  region = "eu-central-1"
  alias  = "europe"

  profile = "admin-1"

  assume_role {
    role_arn = "arn:aws:iam::590184057477:role/yicun-iac"
  }
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

resource "aws_s3_bucket" "us_west_sample_bucket" {
  provider = aws.west
  bucket_prefix = "sample-"
}

resource "aws_s3_object" "us_west_examplebucket_object" {
  provider = aws.west
  key    = "app"
  bucket = aws_s3_bucket.us_west_sample_bucket.id
  source = "./supplement/app.zip"
}

# Elastic Beanstalk application
resource "aws_elastic_beanstalk_application" "us_west" {
  provider = aws.west
  name        = "my-global-app"
  description = "A global application deployed in US-West."
}

resource "aws_elastic_beanstalk_application_version" "us_west_version" {
  provider = aws.west
  name        = "v1"
  application = aws_elastic_beanstalk_application.us_west.name
  bucket = aws_s3_object.us_west_examplebucket_object.bucket
  key    = aws_s3_object.us_west_examplebucket_object.key
}

# US-West Elastic Beanstalk Environment
resource "aws_elastic_beanstalk_environment" "us_west" {
  provider            = aws.west
  name                = "my-global-app-us-west"
  application         = aws_elastic_beanstalk_application.us_west.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.3.0 running Python 3.9"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }
}

resource "aws_s3_bucket" "eu_sample_bucket" {
  provider = aws.europe
  bucket_prefix = "sample-"
}

resource "aws_s3_object" "eu_examplebucket_object" {
  provider = aws.europe
  key    = "app"
  bucket = aws_s3_bucket.eu_sample_bucket.id
  source = "./supplement/app.zip"
}

# Elastic Beanstalk Application (EU-Central Region)
resource "aws_elastic_beanstalk_application" "eu_central" {
  provider = aws.europe
  name        = "my-global-app"
  description = "A global application deployed in EU-Central."
}

resource "aws_elastic_beanstalk_application_version" "europe_version" {
  provider = aws.europe
  name        = "v1"
  application = aws_elastic_beanstalk_application.eu_central.name
  bucket = aws_s3_object.eu_examplebucket_object.bucket
  key    = aws_s3_object.eu_examplebucket_object.key
}

# EU-Central Elastic Beanstalk Environment
resource "aws_elastic_beanstalk_environment" "eu_central" {
  provider            = aws.europe
  name                = "my-global-app-eu-central"
  application         = aws_elastic_beanstalk_application.eu_central.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.3.0 running Python 3.9"

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

