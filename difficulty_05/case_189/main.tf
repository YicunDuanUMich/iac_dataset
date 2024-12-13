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

# Create a Virtual Private Cloud (VPC)
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Create Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
}

# Create Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
}


data "aws_ami" "latest_amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["*ubuntu-noble-24.04-amd64-server-*"]
  }
}

# Create Launch Template for EC2 instances
resource "aws_launch_template" "ec2_launch_template" {
  name = "my-launch-template"

  instance_type = "t2.micro"
  image_id = data.aws_ami.latest_amazon_linux_2.id
}

# Create EC2 Fleet
resource "aws_ec2_fleet" "ec2_fleet" {
  launch_template_config {
    launch_template_specification {
      launch_template_id = aws_launch_template.ec2_launch_template.id
      version            = aws_launch_template.ec2_launch_template.latest_version
    }
  }

  target_capacity_specification {
    default_target_capacity_type = "on-demand"
    total_target_capacity        = 9
    on_demand_target_capacity    = 5
    spot_target_capacity         = 4
  }

  excess_capacity_termination_policy = "termination"
  replace_unhealthy_instances = true
  terminate_instances = true

  # Additional configurations can be added as needed
}
