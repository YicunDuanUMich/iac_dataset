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
# RDS database instance
resource "aws_db_instance" "my_db1" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql" 
  engine_version       = "8.0" 
  instance_class       = "db.t3.micro"
  username             = "dbadmin"
  password             = "dbpassword" 
  parameter_group_name = "default.mysql8.0"
  multi_az             = true 
  apply_immediately    = true 
  skip_final_snapshot  = true
}

# Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "my_app" {
  name        = "my-application"
  description = "My Auto-Scaling Application"
}

# Elastic Beanstalk Environment with Auto-Scaling
resource "aws_elastic_beanstalk_environment" "my_app_env" {
  name                = "my-application-env"
  application         = aws_elastic_beanstalk_application.my_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.11 running Python 3.11"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.small" 
  }

  setting {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "IamInstanceProfile"
      value     = aws_iam_instance_profile.eb_ec2_profile.name
    }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1" 
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "4"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerThreshold"
    value     = "20"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperThreshold"
    value     = "60"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_HOST"
    value     = aws_db_instance.my_db1.address
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_USER"
    value     = aws_db_instance.my_db1.username
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_PASSWORD"
    value     = aws_db_instance.my_db1.password
  }
}