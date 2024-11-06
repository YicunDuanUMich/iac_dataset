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

# Create Private Subnet 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

# Create Private Subnet 2
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"
}

# Create Security Group for EC2 instances
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.my_vpc.id
  name   = "web_sg"

  # Define inbound and outbound rules as needed
}

# Create EC2 instance in the Public Subnet (Web Server)
resource "aws_instance" "web_instance" {
  ami             = "ami-0230bd60aa48260c6" # Use the desired AMI ID
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.web_sg.id]

  # Additional configurations can be added as needed
}

# Create EC2 instance in Private Subnet 1 (Application Server)
resource "aws_instance" "app_instance" {
  ami           = "ami-0230bd60aa48260c6" # Use the desired AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet_1.id

  # Additional configurations can be added as needed
}

# Create RDS instance in Private Subnet 2 (Database)
resource "aws_db_instance" "db_instance" {
  identifier           = "mydb"
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  allocated_storage    = 20
  storage_type         = "gp2"
  username             = "admin"
  password             = "your-password" # Replace with your desired password

}