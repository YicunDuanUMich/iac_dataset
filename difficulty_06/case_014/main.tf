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


resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "user"
  password             = "mypassword"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_elastic_beanstalk_application" "default" {
  name        = "my-app"
  description = "My awesome application"
}

resource "aws_elastic_beanstalk_environment" "default" {
  name                = "my-app-env"
  application         = aws_elastic_beanstalk_application.default.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.11 running Python 3.11"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = "public"
  }

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
    namespace = "aws:rds:dbinstance"
    name      = "DBUser"
    value     = aws_db_instance.default.username
  }

  setting {
    namespace = "aws:rds:dbinstance"
    name      = "DBPassword"
    value     = aws_db_instance.default.password
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_HOST"
    value     = aws_db_instance.default.address
  }



  setting {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "IamInstanceProfile"
      value     = aws_iam_instance_profile.eb_ec2_profile.name
    }
}