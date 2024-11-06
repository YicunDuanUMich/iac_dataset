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

resource "random_string" "db_password" {
  keepers = {
    region = "us-east-2"
  }

  special = false
  length  = 20
}

resource "aws_db_instance" "main" {
  identifier_prefix      = "go-cloud-test"
  engine                 = "mysql"
  engine_version         = "5.6.39"
  instance_class         = "db.t2.micro"
  allocated_storage      = 20
  username               = "root"
  password               = random_string.db_password.result
  db_name                = "testdb"
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.main.id]
  skip_final_snapshot    = false
}

resource "aws_security_group" "main" {
  name_prefix = "testdb"
  description = "Security group for the Go CDK MySQL test database."

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Public MySQL access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outgoing traffic allowed"
  }
}