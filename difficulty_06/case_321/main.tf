resource "aws_s3_bucket" "video_content" {
}

resource "aws_lb" "netflix_alb" {
  subnets = [aws_subnet.netflix_vpc_subnet_a.id, aws_subnet.netflix_vpc_subnet_b.id]

  security_groups = [aws_security_group.netflix_vpc_sg.id]
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.netflix_alb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.netflix_tg.arn
  }
}

resource "aws_lb_target_group" "netflix_tg" {
  vpc_id   = aws_vpc.netflix_vpc.id
  port     = 443
  protocol = "HTTPS"
}

resource "aws_lb_target_group_attachment" "instance_a" {
  target_group_arn = aws_lb_target_group.netflix_tg.arn
  target_id        = aws_instance.instance_a.id
}

data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "instance_a" {
  ami           = data.aws_ami.amzn-linux-2023-ami.id
  instance_type = "t2.micro"
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
  name   = "allow_tls"
  vpc_id = aws_vpc.netflix_vpc.id
}

resource "aws_route53_zone" "netflix_zone" {
  name = "netflix.com"
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