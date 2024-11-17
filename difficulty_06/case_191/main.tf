# Define the provider (AWS in this case)
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

data "aws_availability_zones" "available" {
  state = "available"
}

# Create Private Subnet 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
}

# Create Private Subnet 2
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
}

# Create Security Group for EC2 instances
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.my_vpc.id
  name   = "ec2_sg"
}

resource "aws_vpc_security_group_ingress_rule" "ingress1" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 80
  ip_protocol = "tcp"
  to_port = 80
}

resource "aws_vpc_security_group_ingress_rule" "ingress2" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 22
  ip_protocol = "tcp"
  to_port = 22
}

# Allow NFS traffic
resource "aws_vpc_security_group_ingress_rule" "ingress3" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 2049
  ip_protocol = "tcp"
  to_port = 2049
}

resource "aws_vpc_security_group_egress_rule" "egress1" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Create EFS File System
resource "aws_efs_file_system" "efs" {
  creation_token = "my-efs"
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}

# Create EFS Mount Target for Private Subnet 1
resource "aws_efs_mount_target" "mount_target_1" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.private_subnet_1.id
  security_groups = [aws_security_group.ec2_sg.id]
}

# Create EFS Mount Target for Private Subnet 2
resource "aws_efs_mount_target" "mount_target_2" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.private_subnet_2.id
  security_groups = [aws_security_group.ec2_sg.id]
}

data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["*ubuntu-noble-24.04-amd64-server-*"]
  }
}

# Create EC2 instances in Private Subnet 1 and Subnet 2
resource "aws_instance" "ec2_instance_1" {
  ami             = data.aws_ami.amzn2.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private_subnet_1.id
  security_groups = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              mkdir /mnt/efs
              mount -t efs ${aws_efs_file_system.efs.id}:/ /mnt/efs
              EOF
}

resource "aws_instance" "ec2_instance_2" {
  ami             = data.aws_ami.amzn2.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private_subnet_2.id
  security_groups = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              mkdir /mnt/efs
              mount -t efs ${aws_efs_file_system.efs.id}:/ /mnt/efs
              EOF
}

output "ami_id" {
  value = data.aws_ami.amzn2.id
}

output "ami_name" {
  value = data.aws_ami.amzn2.name
}

output "efs_id" {
  value = aws_efs_file_system.efs.id
}