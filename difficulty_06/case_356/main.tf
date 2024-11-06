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

resource "aws_db_proxy" "rds_proxy" {
  name                   = "${aws_rds_cluster.rds_cluster.cluster_identifier}-proxy"
  debug_logging          = false
  engine_family          = "MYSQL"
  idle_client_timeout    = 1800
  require_tls            = true
  role_arn               = aws_iam_role.proxy_role.arn
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  vpc_subnet_ids         = [aws_subnet.rds_subnet_a.id, aws_subnet.rds_subnet_b.id]

  auth {
    auth_scheme = "SECRETS"
    description = "RDS proxy auth for ${aws_rds_cluster.rds_cluster.cluster_identifier}"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret_version.rds_credentials_version.arn
  }

  tags = {
    Name = "${aws_rds_cluster.rds_cluster.cluster_identifier}-proxy"
  }
}

resource "aws_rds_cluster" "rds_cluster" {
  cluster_identifier      = "rds-cluster"
  engine                  = "aurora-mysql"
  engine_version          = "8.0.mysql_aurora.3.02.0"
  database_name           = "mydatabase"
  master_username         = "var.db_username"
  master_password         = "var.db_password"
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"

  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name

  skip_final_snapshot = false

  final_snapshot_identifier = "snapshot"

  tags = {
    Name = "rds-cluster"
  }
}

resource "aws_security_group" "rds_sg" {
  name   = "rds-cluster-sg"
  vpc_id = aws_vpc.rds_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    self            = true # This allows instances associated with this security group to accept traffic from other instances associated with the same security group.
    security_groups = [aws_security_group.ec2_sg.id]
  }

  # Allow to send TCP traffic on port 3306 to any IP address
  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-cluster-sg"
  }
}

resource "aws_subnet" "rds_subnet_a" {
  vpc_id            = aws_vpc.rds_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "subnet-a"
  }
}

resource "aws_subnet" "rds_subnet_b" {
  vpc_id            = aws_vpc.rds_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "subnet-b"
  }
}

resource "aws_vpc" "rds_vpc" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc"
  }
}

resource "aws_security_group" "ec2_sg" {
  name   = "ec2_name-sg"
  vpc_id = aws_vpc.rds_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg"
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "subnet-group"
  subnet_ids = [aws_subnet.rds_subnet_a.id, aws_subnet.rds_subnet_b.id]

  tags = {
    Name        = "subnet-group"
    Environment = "testing"
  }
}

resource "aws_secretsmanager_secret_version" "rds_credentials_version" {
  secret_id     = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({ "username" : "var.db_username", "password" : "var.db_password" })
}

resource "aws_iam_role" "proxy_role" {
  name = "${aws_rds_cluster.rds_cluster.cluster_identifier}-proxy-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "db-secrets"
  description = "RDS DB credentials"
}