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
  from_port       = 5432
  to_port         = 5432
  ip_protocol     = "tcp"
  cidr_ipv4       = "0.0.0.0/0"
  security_group_id = aws_security_group.db-sg.id
}

resource "aws_vpc_security_group_egress_rule" "db-sg-egress-rule" {
  from_port       = 5432
  to_port         = 5432
  ip_protocol     = "tcp"
  cidr_ipv4       = "0.0.0.0/0"
  security_group_id = aws_security_group.db-sg.id
}

resource "aws_db_parameter_group" "postgre-param-group" {
  name   = "pgparamgrp15"
  family = "postgres15"

  parameter {
    name  = "password_encryption"
    value = "scram-sha-256"
  }

  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_kms_key" "rds-key" {
  description             = "kmsrds"
  deletion_window_in_days = 14
}

resource "aws_db_instance" "postgres" {
  identifier                      = "pg"
  skip_final_snapshot             = true
  apply_immediately               = true
  allocated_storage               = 5
  backup_retention_period         = 7
  db_subnet_group_name            = aws_db_subnet_group.db-subnet-group.id
  parameter_group_name            = aws_db_parameter_group.postgre-param-group.name
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  engine                          = "postgres"
  engine_version                  = "15"
  instance_class                  = "db.t3.micro"
  db_name                         = "postgres" # Initial database name
  username                        = "myusername"
  password                        = "mypassword"
  vpc_security_group_ids          = [aws_security_group.db-sg.id]
  # Other security settings
  publicly_accessible             = true
  multi_az                        = true
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.rds-key.arn
  # Default daily backup window
  # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithAutomatedBackups.html#USER_WorkingWithAutomatedBackups.BackupWindow
}