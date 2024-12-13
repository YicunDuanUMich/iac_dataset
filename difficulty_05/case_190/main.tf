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

# Create Private Subnet 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
}

# Create Private Subnet 2
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[2]
}

# Create Security Group for EC2 instances
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.my_vpc.id
  name   = "web_sg"

  # Define inbound and outbound rules as needed
}

data "aws_ami" "latest_amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["*ubuntu-noble-24.04-amd64-server-*"]
  }
}

# Create EC2 instance in the Public Subnet (Web Server)
resource "aws_instance" "web_instance" {
  ami             =  data.aws_ami.latest_amazon_linux_2.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.web_sg.id]

  # Additional configurations can be added as needed
}

# Create EC2 instance in Private Subnet 1 (Application Server)
resource "aws_instance" "app_instance" {
  ami           = data.aws_ami.latest_amazon_linux_2.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet_1.id

  # Additional configurations can be added as needed
}

resource "aws_db_subnet_group" "main" {
  name       = "mydb-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

# Create RDS instance in Private Subnet 2 (Database)
resource "aws_db_instance" "db_instance" {
  identifier           = "mydb"
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  username             = "admin"
  password             = "your-password" # Replace with your desired password
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.main.name
}