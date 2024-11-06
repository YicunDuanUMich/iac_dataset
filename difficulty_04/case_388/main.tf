
# Define the provider block for AWS
provider "aws" {
  region = "us-east-2" # Set your desired AWS region
}


resource "aws_instance" "my_instance" {
  ami           = "ami-06d4b7182ac3480fa" # Replace with your desired AMI ID
  instance_type = "t2.micro"     # Replace with your desired instance type
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "test" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Main"
  }
}

resource "aws_lb" "test" {
    load_balancer_type = "application"
    subnets = [aws_subnet.test.id]
}

resource "aws_lb_target_group" "target_group" {
    port = 80
    protocol = "HTTP"
    vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.test.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

resource "aws_lb_target_group_attachment" "ec2_attach" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id = aws_instance.my_instance.id
}