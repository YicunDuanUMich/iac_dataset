# Define the provider (AWS in this case)
provider "aws" {
  region = "us-east-1"
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

# Create Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
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

# Create EC2 instances in the Placement Group in the Private Subnet
resource "aws_instance" "ec2_instance" {
  count           = 3
  ami             = "ami-0230bd60aa48260c6" # Use the desired AMI ID
  instance_type   = "m5.large"
  subnet_id       = aws_subnet.private_subnet.id
  security_groups = [aws_security_group.ec2_sg.id]
  placement_group = aws_placement_group.my_placement_group.name

}