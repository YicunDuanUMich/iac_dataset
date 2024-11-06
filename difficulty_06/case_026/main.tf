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

# Create the RDS database used by both the blue and green environments
resource "aws_db_instance" "myapp_db" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "myappuser"
  password             = "mysecurepassword"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}

# Create an Elastic Beanstalk application
resource "aws_elastic_beanstalk_application" "myapp" {
  name        = "my-app"
  description = "My application"
}

# Blue environment
resource "aws_elastic_beanstalk_environment" "blue" {
  name                = "my-app-blue"
  application         = aws_elastic_beanstalk_application.myapp.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.11 running Python 3.11"

  # Example setting to connect to the RDS instance
setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_HOST"
    value     = aws_db_instance.myapp_db.address
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_USERNAME"
    value     = aws_db_instance.myapp_db.username
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_PASSWORD"
    value     = aws_db_instance.myapp_db.password
  }

      setting {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "IamInstanceProfile"
      value     = aws_iam_instance_profile.eb_ec2_profile.name
    }
}

# Green environment (new version)
resource "aws_elastic_beanstalk_environment" "green" {
  name                = "my-app-green"
  application         = aws_elastic_beanstalk_application.myapp.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.11 running Python 3.11"

setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_HOST"
    value     = aws_db_instance.myapp_db.address
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_USERNAME"
    value     = aws_db_instance.myapp_db.username
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_PASSWORD"
    value     = aws_db_instance.myapp_db.password
  }

      setting {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "IamInstanceProfile"
      value     = aws_iam_instance_profile.eb_ec2_profile.name
    }
}

# DNS setup with Route 53
resource "aws_route53_zone" "myapp_zone" {
  name = "myapp.com"
}

# Health check for blue environment
resource "aws_route53_health_check" "blue" {
  fqdn              = aws_elastic_beanstalk_environment.blue.cname
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
}

# Health check for green environment
resource "aws_route53_health_check" "green" {
  fqdn              = aws_elastic_beanstalk_environment.green.cname
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
}

# Record set for the blue environment
resource "aws_route53_record" "blue" {
  zone_id = aws_route53_zone.myapp_zone.zone_id
  name    = "blue.myapp.com"
  type    = "CNAME"
  ttl     = "5"
  records = [aws_elastic_beanstalk_environment.blue.cname]
  set_identifier = "BlueEnv"
  failover_routing_policy {
    type = "PRIMARY"
  }
  health_check_id = aws_route53_health_check.blue.id
}

# Record set for the green environment using CNAME
resource "aws_route53_record" "green" {
  zone_id = aws_route53_zone.myapp_zone.zone_id
  name    = "green.myapp.com"
  type    = "CNAME"
  ttl     = "5"
  records = [aws_elastic_beanstalk_environment.green.cname]
  set_identifier = "greenEnv"
  failover_routing_policy {
    type = "SECONDARY"
  }
  health_check_id = aws_route53_health_check.green.id
}