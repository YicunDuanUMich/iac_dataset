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

# Create a Virtual Private Cloud (VPC)
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

data "aws_availability_zones" "azs" {
    state = "available"
}

# Create Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.azs.names[0]
}

# Create EC2 Placement Group
resource "aws_placement_group" "my_placement_group" {
  name     = "my-placement-group"
  strategy = "cluster"
}

# Create Security Group for EC2 instances
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.my_vpc.id
  name   = "ec2_sg"
}

data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["*ubuntu-noble-24.04-amd64-server-*"]
  }
}

# Create EC2 instances in the Placement Group in the Private Subnet
resource "aws_instance" "ec2_instance" {
  count           = 3
  ami             = data.aws_ami.amzn2.id
  instance_type   = "m5.large"
  subnet_id       = aws_subnet.private_subnet.id
  security_groups = [aws_security_group.ec2_sg.id]
  placement_group = aws_placement_group.my_placement_group.name
}