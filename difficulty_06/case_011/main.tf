provider "aws" {
  region = "us-west-2" 
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

# Assuming you have a hosted zone for your domain in Route 53.
# Route 53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = "example56.com"
}

# DNS Record to point to the Elastic Beanstalk environment
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example56.com"
  type    = "CNAME"
  ttl     = "60"
  records = [aws_elastic_beanstalk_environment.eb-env.cname]
}

resource "aws_s3_bucket" "sampleapril26426" {
  bucket = "sampleapril26426"
}

resource "aws_s3_object" "examplebucket_object" {
  key    = "randofile"
  bucket = aws_s3_bucket.sampleapril26426.id
  source = "app.zip"
}

# Define the Elastic Beanstalk application
resource "aws_elastic_beanstalk_application" "myapp" {
  name        = "something-application"
}

# Define the Elastic Beanstalk application version
resource "aws_elastic_beanstalk_application_version" "version" {
  name        = "app-version"
  application = aws_elastic_beanstalk_application.myapp.name
  bucket = aws_s3_object.examplebucket_object.bucket
  key    = aws_s3_object.examplebucket_object.key
}


# Elastic Beanstalk environment
resource "aws_elastic_beanstalk_environment" "eb-env" {
  name                = "awesomeenv"
  application         = aws_elastic_beanstalk_application.myapp.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.2.3 running Corretto 17"
  version_label = aws_elastic_beanstalk_application_version.version.name

    setting {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "IamInstanceProfile"
      value     = aws_iam_instance_profile.eb_ec2_profile.name
    }

}