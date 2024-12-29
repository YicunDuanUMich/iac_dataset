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

data "aws_ami" "latest_amazon_linux_2" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Create a Virtual Private Cloud (VPC)
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

data "aws_availability_zones" "azs" {
    state = "available"
}

resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.azs.names[0]
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.azs.names[1]
}

# Create an EC2 instance in Subnet A
resource "aws_instance" "ec2_instance_a" {
  ami           = data.aws_ami.latest_amazon_linux_2.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet_a.id

  root_block_device {
    volume_size = 50
  }
}

# # Create an EC2 instance in Subnet B
resource "aws_instance" "ec2_instance_b" {
  ami           = data.aws_ami.latest_amazon_linux_2.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet_b.id

  root_block_device {
    volume_size = 50
  }
}