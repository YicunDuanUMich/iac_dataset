provider "aws" {
  region = "us-west-1"
}

resource "aws_s3_bucket" "video_content" {
  bucket = "video-content-bucket"

  tags = {
    Application = "netflix-lb"
  }
}

resource "aws_lb" "netflix_alb" {
  name = "video-streaming-alb"

  load_balancer_type = "application"

  subnets = [aws_subnet.netflix_vpc_subnet_a.id, aws_subnet.netflix_vpc_subnet_b.id]

  security_groups = [aws_security_group.netflix_vpc_sg.id]
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.netflix_alb.arn
  port              = 443
  protocol          = "HTTPS"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.netflix_tg.arn
  }
}

resource "aws_lb_target_group" "netflix_tg" {
  name     = "netflix-lb-tg"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.netflix_vpc.id
}

resource "aws_lb_target_group_attachment" "instance_a" {
  target_group_arn = aws_lb_target_group.netflix_tg.arn
  target_id        = aws_instance.instance_a.id
  port             = 443
}

data "aws_ami" "amzn_linux_2023_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_key_pair" "instance_a_key_pair" {
  public_key = file("key.pub")
}

resource "aws_instance" "instance_a" {
  ami           = data.aws_ami.amzn_linux_2023_ami.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.instance_a_key_pair.key_name
}

resource "aws_vpc" "netflix_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "netflix_vpc_subnet_a" {
  vpc_id     = aws_vpc.netflix_vpc.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "netflix_vpc_subnet_b" {
  vpc_id     = aws_vpc.netflix_vpc.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_security_group" "netflix_vpc_sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and outbound traffic"
  vpc_id      = aws_vpc.netflix_vpc.id

  tags = {
    Name = "netflix-lb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.netflix_vpc_sg.id
  cidr_ipv4         = aws_vpc.netflix_vpc.cidr_block
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.netflix_vpc_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_route53_zone" "netflix_zone" {
  name = "netflix.com"

  tags = {
    Application = "netflix-lb"
  }
}

resource "aws_route53_record" "lb_ipv4" {
  type    = "A"
  name    = "lb"
  zone_id = aws_route53_zone.netflix_zone.zone_id

  alias {
    name                   = aws_lb.netflix_alb.dns_name
    zone_id                = aws_lb.netflix_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "lb_ipv6" {
  type    = "AAAA"
  name    = "lb"
  zone_id = aws_route53_zone.netflix_zone.zone_id

  alias {
    name                   = aws_lb.netflix_alb.dns_name
    zone_id                = aws_lb.netflix_alb.zone_id
    evaluate_target_health = true
  }
}