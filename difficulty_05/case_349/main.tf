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

resource "aws_db_instance" "db" {

  identifier = "identifier"

  engine            = "postgres"
  engine_version    = "14.3"
  instance_class    = "db.t2.micro"
  allocated_storage = 5

  db_name  = "var.name"
  username = "var.username"
  password = "var.password"

  db_subnet_group_name   = aws_db_subnet_group.default.name

  availability_zone = "eu-west-2a"

  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = true
  apply_immediately           = true
  max_allocated_storage       = 50

  skip_final_snapshot     = true
  backup_retention_period = 5
  backup_window           = "03:00-06:00"
  maintenance_window      = "Mon:00:00-Mon:03:00"
  publicly_accessible = false
  //  final_snapshot_identifier = "${var.identifier}-snapshot"
  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = merge(
    {
      "Name" = "var.identifier"
    },
  )

  timeouts {
    create = "40m"
    update = "80m"
    delete = "40m"
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.main.id]

}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Main"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}