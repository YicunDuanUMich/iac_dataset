terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}
# Define the provider block for AWS
provider "aws" {
  region = "us-east-2" # Set your desired AWS region
}

variable "vpc_id" {
  type        = string
  description = "The VPC to deploy the components within"
  default = "vpc-12345678"
}

variable "pg_port" {
  type        = number
  description = "Postgres connection port"
  default     = 5432
}

variable "pg_superuser_username" {
  type        = string
  description = "Username for the 'superuser' user in the Postgres instance"
  default     = "superuser"
}

variable "pg_superuser_password" {
  type        = string
  sensitive   = true
  description = "Password for the 'superuser' user in the Postgres instance"
  default = "random-password"
}

resource "aws_db_subnet_group" "postgres" {
  name       = "pgsubnetgrp"
  subnet_ids = [aws_subnet.main1.id, aws_subnet.main2.id]
}

resource "aws_subnet" "main1" {
  vpc_id     = var.vpc_id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Main"
  }
}

resource "aws_subnet" "main2" {
  vpc_id     = var.vpc_id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Main"
  }
}

resource "aws_db_parameter_group" "postgres" {
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

resource "aws_security_group" "pg" {
  name   = "pg"
  vpc_id = var.vpc_id

  ingress {
    description = "Postgres from internet"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "TCP"
    self        = false
  }
  egress {
    description = "Postgres to internet"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "TCP"
    self        = false
  }
}

resource "aws_kms_key" "rds_key" {
  description             = "kmsrds"
  deletion_window_in_days = 14
  tags                    = { Name = "kmsrds" }
}

resource "aws_db_instance" "postgres" {
  identifier                      = "pg"
  final_snapshot_identifier       = "pgsnapshot"
  allocated_storage               = 20
  apply_immediately               = true
  backup_retention_period         = 7
  db_subnet_group_name            = aws_db_subnet_group.postgres.name
  parameter_group_name            = aws_db_parameter_group.postgres.name
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  engine                          = "postgres"
  engine_version                  = "15"
  allow_major_version_upgrade     = true
  instance_class                  = "db.t3.micro"
  db_name                         = "postgres" # Initial database name
  username                        = var.pg_superuser_username
  port                            = var.pg_port
  password                        = var.pg_superuser_password
  vpc_security_group_ids          = [aws_security_group.pg.id]
  # Other security settings
  publicly_accessible = false
  multi_az            = true
  storage_encrypted   = true
  kms_key_id          = aws_kms_key.rds_key.arn
  # Default daily backup window
  # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithAutomatedBackups.html#USER_WorkingWithAutomatedBackups.BackupWindow
}