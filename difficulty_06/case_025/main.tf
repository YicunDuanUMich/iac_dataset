provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"
}


resource "aws_iam_role" "eb_ec2_role3" {
    provider = aws.us_east_1
  name = "elastic_beanstalk_ec2_role3"

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
resource "aws_iam_role_policy_attachment" "eb_managed_policy3" {
    provider = aws.us_east_1
  role       = aws_iam_role.eb_ec2_role3.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}


# Create an instance profile tied to the role
resource "aws_iam_instance_profile" "eb_ec2_profile3" {
    provider = aws.us_east_1
  name = "elastic_beanstalk_ec2_profile3"
  role = aws_iam_role.eb_ec2_role3.name
}

# RDS in US East (N. Virginia)
resource "aws_db_instance" "main_db_us_east" {
  provider             = aws.us_east_1
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "dbadmin"
  password             = "mysecurepassword"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  multi_az             = true
}

# Elastic Beanstalk Application in US East
resource "aws_elastic_beanstalk_application" "myapp_us_east" {
  provider = aws.us_east_1
  name     = "my-application-us-east"
}

# Elastic Beanstalk Environment in US East
resource "aws_elastic_beanstalk_environment" "myenv_us_east" {
  provider            = aws.us_east_1
  name                = "my-application-env-us-east"
  application         = aws_elastic_beanstalk_application.myapp_us_east.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.11 running Python 3.11"


    setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_HOST"
    value     = aws_db_instance.main_db_us_east.address
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_USERNAME"
    value     = aws_db_instance.main_db_us_east.address
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_PASSWORD"
    value     = aws_db_instance.main_db_us_east.address
  }

      setting {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "IamInstanceProfile"
      value     = aws_iam_instance_profile.eb_ec2_profile3.name
    }
}

# RDS in EU West (Ireland)
resource "aws_db_instance" "main_db_eu_west" {
  provider             = aws.eu_west_1
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  multi_az             = true
  username             = "dbadmin"
  password             = "mysecurepassword"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

# Elastic Beanstalk Application in EU West
resource "aws_elastic_beanstalk_application" "myapp_eu_west" {
  provider = aws.eu_west_1
  name     = "my-application-eu-west"
}

# Elastic Beanstalk Environment in EU West
resource "aws_elastic_beanstalk_environment" "myenv_eu_west" {
  provider            = aws.eu_west_1
  name                = "my-application-env-eu-west"
  application         = aws_elastic_beanstalk_application.myapp_eu_west.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.11 running Python 3.11"

setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_HOST"
    value     = aws_db_instance.main_db_eu_west.address
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_USERNAME"
    value     = aws_db_instance.main_db_eu_west.address
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_PASSWORD"
    value     = aws_db_instance.main_db_eu_west.address
  }

      setting {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "IamInstanceProfile"
      value     = aws_iam_instance_profile.eb_ec2_profile3.name
    }
}

# Main Route 53 Hosted Zone
resource "aws_route53_zone" "main" {
    provider = aws.us_east_1
  name = "myapp.com"
}

# Latency Based Routing in Route 53 for US East Elastic Beanstalk Environment
resource "aws_route53_record" "eb_env_us_east" {
    provider = aws.us_east_1
  zone_id = aws_route53_zone.main.zone_id
  name    = "us-east.myapp.com"
  type    = "CNAME"
  ttl     = "60"
  records = [aws_elastic_beanstalk_environment.myenv_us_east.cname]
    set_identifier = "EastEnv"
  latency_routing_policy {
    region = "us-east-1"
  }
}

resource "aws_route53_record" "eb_env_eu_west" {
    provider = aws.eu_west_1
  zone_id = aws_route53_zone.main.zone_id
  name    = "eu-west.myapp.com"
  type    = "CNAME"
  ttl     = "60"
  records = [aws_elastic_beanstalk_environment.myenv_eu_west.cname]
  set_identifier = "WestEnv"
  latency_routing_policy {
    region = "eu-west-1"
  }
}
