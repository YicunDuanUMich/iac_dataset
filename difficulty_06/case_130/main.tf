# Define the provider (AWS in this case)
provider "aws" {
  region = "us-east-1"
}

# Create a Virtual Private Cloud (VPC)
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create Private Subnet 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

# Create Private Subnet 2
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

# Create Security Group for EC2 instances
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.my_vpc.id
  name   = "ec2_sg"

  # Define inbound and outbound rules as needed
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

# Create EC2 instances in Private Subnet 1 and Subnet 2
resource "aws_instance" "ec2_instance_1" {
  ami             = "ami-0230bd60aa48260c6" # Use the desired AMI ID
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
  ami             = "ami-0230bd60aa48260c6" # Use the desired AMI ID
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private_subnet_2.id
  security_groups = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              mkdir /mnt/efs
              mount -t efs ${aws_efs_file_system.efs.id}:/ /mnt/efs
              EOF
}