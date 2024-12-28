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

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = "main-vpc"
  cidr = "10.0.0.0/16"

  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["*ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_security_group" "lb-sg" {
  name = "lb-sg"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "lb-sg-ingress-rule" {
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
  security_group_id = aws_security_group.lb-sg.id
}

resource "aws_vpc_security_group_egress_rule" "lb-sg-egress-rule" {
  from_port   = 0
  to_port     = 0
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
  security_group_id = aws_security_group.lb-sg.id
}


resource "aws_iam_role" "lambda_role" {
  name = "example-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_policy_attachment" {
  name       = "example-lambda-policy-attachment"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda-func" {
  type        = "zip"
  source_file = "./supplement/index.js"
  output_path = "./supplement/lambda_func.zip"
}

resource "aws_lambda_function" "example" {
  function_name = "example-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  filename         = data.archive_file.lambda-func.output_path
  source_code_hash = data.archive_file.lambda-func.output_base64sha256
}

resource "aws_lambda_permission" "elb_invocation" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.target_group.arn
}

resource "aws_lb" "test" {
  subnets            = module.vpc.public_subnets
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb-sg.id]
}

resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

resource "aws_lb_target_group" "target_group" {
  target_type = "lambda"
}

resource "aws_lb_target_group_attachment" "ec2_attach" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id = aws_lambda_function.example.arn
}