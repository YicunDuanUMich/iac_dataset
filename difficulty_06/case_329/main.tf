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

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = "main-vpc"
  cidr = "10.0.0.0/16"

  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

resource "aws_db_subnet_group" "db-subnet-group" {
  name       = "db-subnet-group"
  subnet_ids = module.vpc.public_subnets
}

resource "aws_security_group" "db-sg" {
  name = "db-sg"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "db-sg-ingress-rule" {
  from_port       = 3306
  to_port         = 3306
  ip_protocol     = "tcp"
  cidr_ipv4       = "0.0.0.0/0"
  security_group_id = aws_security_group.db-sg.id
}

resource "aws_vpc_security_group_egress_rule" "db-sg-egress-rule" {
  from_port       = 3306
  to_port         = 3306
  ip_protocol     = "tcp"
  cidr_ipv4       = "0.0.0.0/0"
  security_group_id = aws_security_group.db-sg.id
}

resource "aws_db_instance" "database" {
  identifier             = "dolphinscheduler"
  db_name                = "dolphinscheduler"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "mysql"
  engine_version         = "8.4.3"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.db-subnet-group.id
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.db-sg.id]
  username               = "myusername"
  password               = "mypassword"
}
