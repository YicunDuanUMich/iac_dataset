# Define the provider block for AWS
provider "aws" {
  region = "us-east-2" # Set your desired AWS region
}


resource "aws_instance" "my_instance" {
  ami           = "ami-06d4b7182ac3480fa" # Replace with your desired AMI ID
  instance_type = "t2.micro"     # Replace with your desired instance type
  subnet_id     = aws_subnet.example1.id
}

resource "aws_lb" "test" {
  subnets            = [aws_subnet.example1.id, aws_subnet.example2.id]
}

resource "aws_subnet" "example1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"
}

resource "aws_subnet" "example2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-2b"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.test.arn

  default_action {
    type = "authenticate-cognito"

    authenticate_cognito {
      user_pool_arn       = aws_cognito_user_pool.pool.arn
      user_pool_client_id = aws_cognito_user_pool_client.client.id
      user_pool_domain    = aws_cognito_user_pool_domain.domain.domain
    }
  }
}

resource "aws_cognito_user_pool" "pool" {
  name = "mypool"
}

resource "aws_cognito_user_pool_client" "client" {
  name = "client"
  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain       = "example-domain"
  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_lb_target_group" "target_group" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_target_group_attachment" "ec2_attach" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id = aws_instance.my_instance.id
}