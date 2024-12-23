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
  region = "us-east-1"
  profile = "admin-1"

  assume_role {
    role_arn = "arn:aws:iam::590184057477:role/yicun-iac"
  }
}

resource "aws_db_instance" "postgres" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "17.2"
  instance_class         = "db.t4g.micro"
  skip_final_snapshot    = true
  db_name                = "mydbname"
  username               = "username"
  password               = "password"
  vpc_security_group_ids = [aws_security_group.rds-proxy-sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.id
  publicly_accessible    = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name                 = "main-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets       = ["10.0.3.0/24", "10.0.4.0/24"]
}

resource "aws_security_group" "rds-proxy-sg" {
  name        = "rds-proxy-sg"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "db-proxy-sg-ingress-rule" {
  from_port       = 5432
  to_port         = 5432
  ip_protocol     = "tcp"
  cidr_ipv4       = "0.0.0.0/0"
  security_group_id = aws_security_group.rds-proxy-sg.id
}

resource "aws_vpc_security_group_egress_rule" "db-proxy-sg-egress-rule" {
  from_port       = 5432
  to_port         = 5432
  ip_protocol     = "tcp"
  cidr_ipv4       = "0.0.0.0/0"
  security_group_id = aws_security_group.rds-proxy-sg.id
}

resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = module.vpc.private_subnets
}