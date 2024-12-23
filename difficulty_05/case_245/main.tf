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


data "aws_availability_zones" "azs" {
    state = "available"
}

resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.example_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.azs.names[0]
}
resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.example_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.azs.names[1]
}
resource "aws_neptune_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

resource "aws_neptune_cluster_parameter_group" "example" {
  family      = "neptune1.3"
  name        = "example"
  description = "neptune cluster parameter group"

  parameter {
    name  = "neptune_enable_audit_log"
    value = 1
  }
}

resource "aws_neptune_parameter_group" "example" {
  family = "neptune1.3"
  name   = "example"

  parameter {
    name  = "neptune_query_timeout"
    value = "25"
  }
}

resource "aws_neptune_cluster" "default" {
  cluster_identifier                  = "neptune-cluster-demo"
  engine                              = "neptune"
  backup_retention_period             = 5
  preferred_backup_window             = "07:00-09:00"
  skip_final_snapshot                 = true
  iam_database_authentication_enabled = true
  apply_immediately                   = true
  neptune_cluster_parameter_group_name = aws_neptune_cluster_parameter_group.example.id
  neptune_subnet_group_name = aws_neptune_subnet_group.default.id
}

resource "aws_neptune_cluster_instance" "example" {
  count              = 2
  cluster_identifier = aws_neptune_cluster.default.id
  engine             = "neptune"
  instance_class     = "db.t3.medium"
  apply_immediately  = true
  publicly_accessible = false
  neptune_parameter_group_name = aws_neptune_parameter_group.example.id
  neptune_subnet_group_name = aws_neptune_subnet_group.default.id
}