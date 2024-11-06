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

# VPC
resource "aws_vpc" "eb_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Internet Gateway
resource "aws_internet_gateway" "eb_igw" {
  vpc_id = aws_vpc.eb_vpc.id
}

# Subnets
resource "aws_subnet" "eb_subnet_public_1" {
  vpc_id     = aws_vpc.eb_vpc.id
  cidr_block = "10.0.1.0/24"

  map_public_ip_on_launch = true
  availability_zone       = "us-west-2a"
}

resource "aws_subnet" "eb_subnet_public_2" {
  vpc_id     = aws_vpc.eb_vpc.id
  cidr_block = "10.0.2.0/24"

  map_public_ip_on_launch = true
  availability_zone       = "us-west-2b"
}

# Security groups for Elastic Beanstalk environments
resource "aws_security_group" "eb_env_sg" {
  name        = "eb-env-sg"
  description = "Security group for Elastic Beanstalk environments"
  vpc_id      = aws_vpc.eb_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# DB subnet group for RDS instance
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.eb_subnet_public_1.id, aws_subnet.eb_subnet_public_2.id]
}

resource "aws_route_table" "eb_route_table" {
  vpc_id = aws_vpc.eb_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eb_igw.id
  }
}

resource "aws_route_table_association" "eb_route_table_association_1" {
  subnet_id      = aws_subnet.eb_subnet_public_1.id
  route_table_id = aws_route_table.eb_route_table.id
}

resource "aws_route_table_association" "eb_route_table_association_2" {
  subnet_id      = aws_subnet.eb_subnet_public_2.id
  route_table_id = aws_route_table.eb_route_table.id
}
# RDS instance
resource "aws_db_instance" "shared_rds" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  username             = "dbadmin"
  password             = "securepassword" 
  backup_retention_period = 0
  skip_final_snapshot  = true
  db_subnet_group_name  = aws_db_subnet_group.rds_subnet_group.name

  vpc_security_group_ids = [aws_security_group.eb_env_sg.id]
}

# Elastic Beanstalk application
resource "aws_elastic_beanstalk_application" "microservice_app" {
  name        = "MicroserviceApplication"
  description = "An application for microservices"
}

resource "aws_elastic_beanstalk_environment" "microservice_env1" {
  name                = "microservice-env1"
  application         = aws_elastic_beanstalk_application.microservice_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.11 running Python 3.11"

  # Elastic Beanstalk environment variables for RDS connection
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_HOSTNAME"
    value     = aws_db_instance.shared_rds.address
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_USERNAME"
    value     = aws_db_instance.shared_rds.username
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_PASSWORD"
    value     = aws_db_instance.shared_rds.password
  }

    setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.eb_vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.eb_subnet_public_1.id},${aws_subnet.eb_subnet_public_2.id}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.eb_env_sg.id
  }

  setting {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "IamInstanceProfile"
      value     = aws_iam_instance_profile.eb_ec2_profile.name
    }
}

resource "aws_elastic_beanstalk_environment" "microservice_env2" {
  name                = "microservice-env2"
  application         = aws_elastic_beanstalk_application.microservice_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.11 running Python 3.11"

  # Elastic Beanstalk environment variables for RDS connection
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_HOSTNAME"
    value     = aws_db_instance.shared_rds.address
  }


  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_USERNAME"
    value     = aws_db_instance.shared_rds.username
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_PASSWORD"
    value     = aws_db_instance.shared_rds.password
  }

    setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.eb_vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.eb_subnet_public_1.id},${aws_subnet.eb_subnet_public_2.id}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.eb_env_sg.id
  }

  setting {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "IamInstanceProfile"
      value     = aws_iam_instance_profile.eb_ec2_profile.name
    }
}