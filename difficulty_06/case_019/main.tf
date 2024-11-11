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

data "aws_availability_zones" "available" {
  state = "available"
}

# Subnets
resource "aws_subnet" "eb_subnet_public_1" {
  vpc_id     = aws_vpc.eb_vpc.id
  cidr_block = "10.0.1.0/24"

  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "eb_subnet_public_2" {
  vpc_id     = aws_vpc.eb_vpc.id
  cidr_block = "10.0.2.0/24"

  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]
}

# Security groups for Elastic Beanstalk environments
resource "aws_security_group" "eb_env_sg" {
  name        = "eb-env-sg"
  description = "Security group for Elastic Beanstalk environments"
  vpc_id      = aws_vpc.eb_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "ingress1" {
  security_group_id = aws_security_group.eb_env_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "ingress2" {
  security_group_id = aws_security_group.eb_env_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "egress1" {
  security_group_id = aws_security_group.eb_env_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
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
  solution_stack_name = "64bit Amazon Linux 2023 v4.3.0 running Python 3.9"

  # Elastic Beanstalk environment variables for RDS connection
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_HOSTNAME"
    value     = aws_db_instance.shared_rds.address
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_USERNAME"
    value     = aws_db_instance.shared_rds.username
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_PASSWORD"
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
  solution_stack_name = "64bit Amazon Linux 2023 v4.3.0 running Python 3.9"

  # Elastic Beanstalk environment variables for RDS connection
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_HOSTNAME"
    value     = aws_db_instance.shared_rds.address
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_USERNAME"
    value     = aws_db_instance.shared_rds.username
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_PASSWORD"
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