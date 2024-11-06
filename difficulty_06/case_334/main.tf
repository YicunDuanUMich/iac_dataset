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

resource "aws_db_subnet_group" "default" {
  name       = "dbtunnel-public-dbsubnet-group"
  subnet_ids = [aws_subnet.main-subnet-public-dbtunnel.id, aws_subnet.main-subnet-private-dbtunnel.id]

  tags = {
    Name = "dbtunnel-public-dbsubnet-group"
  }
}

# This is mainly a placeholder for settings we might want to configure later.
resource "aws_db_parameter_group" "default" {
  name        = "rds-pg"
  family      = "postgres12"
  description = "RDS default parameter group"

  #parameter {
  #  name  = "character_set_client"
  #  value = "utf8"
  #}
}

# Create the postgres instance on RDS so it's fully managed and low maintenance.
# For now all we care about is testing with postgres.
resource "aws_db_instance" "default" {
  allocated_storage    = 5
  engine               = "postgres"
  engine_version       = "12.6"
  identifier           = "tunnel-dev"
  instance_class       = "db.t3.micro"
  db_subnet_group_name = aws_db_subnet_group.default.name 
  db_name              = "airbyte"
  username             = "airbyte"
  password             = "password"
  parameter_group_name = aws_db_parameter_group.default.name
  publicly_accessible = false
  skip_final_snapshot  = true
  apply_immediately    = true
  vpc_security_group_ids = [aws_security_group.dbtunnel-sg.id]
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Bastion host sits inside a public subnet
resource "aws_subnet" "main-subnet-public-dbtunnel" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.0.0/16"
    map_public_ip_on_launch = "true" 
    availability_zone = "us-west-2"
    tags = {
        Name = "public-dbtunnel"
    }
}

# Because an RDS instance requires two AZs we need another subnet for it
resource "aws_subnet" "main-subnet-private-dbtunnel" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.0.0/16"
    map_public_ip_on_launch = "false"
    availability_zone = "us-west-2"
    tags = {
        Name = "private-dbtunnel"
    }
}

resource "aws_security_group" "dbtunnel-sg" {
  name        = "dbtunnel-sg-allow-postgres"
  description = "Allow inbound traffic but only from the dbtunnel subnet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "tcp on 5432 from subnet"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = [aws_subnet.main-subnet-public-dbtunnel.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "dbtunnel-sg-allow-postgres"
  }
}