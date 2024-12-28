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

resource "aws_security_group" "instance-sg" {
  name = "instance-sg"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "instance-sg-ingress-rule" {
  from_port       = 0
  to_port         = 0
  ip_protocol     = "-1"
  cidr_ipv4   = "0.0.0.0/0"
  security_group_id = aws_security_group.instance-sg.id
}

resource "aws_vpc_security_group_egress_rule" "instance-sg-egress-rule" {
  from_port       = 0
  to_port         = 0
  ip_protocol     = "-1"
  cidr_ipv4       = "0.0.0.0/0"
  security_group_id = aws_security_group.instance-sg.id
}

resource "aws_instance" "my_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = module.vpc.public_subnets[0]
  security_groups = [ aws_security_group.instance-sg.id ]
}

resource "aws_lb" "test" {
  load_balancer_type = "gateway"
  subnet_mapping {
    subnet_id = module.vpc.public_subnets[0]
  }
}

resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.test.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

resource "aws_lb_target_group" "target_group" {
  port     = 6081
  protocol = "GENEVE"
  vpc_id   = module.vpc.vpc_id

  health_check {
    port     = 80
    protocol = "HTTP"
  }
}

resource "aws_lb_target_group_attachment" "ec2_attach" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id = aws_instance.my_instance.id
}