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
  region  = "us-east-1"
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
# RDS Database Configuration
resource "aws_db_instance" "my_db" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "mydbuser"
  password             = "mypassword"
  parameter_group_name = "default.mysql5.7"
  multi_az             = true
  skip_final_snapshot  = true
  backup_retention_period = 7  # Enable backups with 7-day retention
  apply_immediately       = true
}

# Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "my_app" {
  name        = "my-app"
  description = "My Application"
}

# Original Elastic Beanstalk Environment (Blue)
resource "aws_elastic_beanstalk_environment" "blue_env" {
  name                = "my-app-blue-env"
  application         = aws_elastic_beanstalk_application.my_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.3.0 running Python 3.9"
  tier                = "WebServer"

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_HOST"
    value     = aws_db_instance.my_db.address
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_USER"
    value     = aws_db_instance.my_db.username
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_PASS"
    value     = aws_db_instance.my_db.password
  }

  setting {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "IamInstanceProfile"
      value     = aws_iam_instance_profile.eb_ec2_profile.name
  }
}

# New Elastic Beanstalk Environment (Green), for the new version
resource "aws_elastic_beanstalk_environment" "green_env" {
  name                = "my-app-green-env"
  application         = aws_elastic_beanstalk_application.my_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.3.0 running Python 3.9"
  tier                = "WebServer"

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_HOST"
    value     = aws_db_instance.my_db.address
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_USER"
    value     = aws_db_instance.my_db.username
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_PASS"
    value     = aws_db_instance.my_db.password
  }

  setting {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "IamInstanceProfile"
      value     = aws_iam_instance_profile.eb_ec2_profile.name
    }
}

# Taking a snapshot before deployment
resource "aws_db_snapshot" "my_db_snapshot" {
  db_instance_identifier = aws_db_instance.my_db.identifier
  db_snapshot_identifier = "my-db-snapshot-${formatdate("YYYYMMDDHHmmss", timestamp())}"
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
    aws_elastic_beanstalk_environment.blue_env.cname
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
    aws_elastic_beanstalk_environment.green_env.cname
  ]
}