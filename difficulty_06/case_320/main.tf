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

resource "aws_launch_configuration" "launch-config" {
  name_prefix     = "aws-asg-launch-config-"
  image_id        = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  # user_data       = file("user-data.sh")  # load your script if needed
  security_groups = [aws_security_group.instance-sg.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name                 = "asg"
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.launch-config.name
  vpc_zone_identifier  = module.vpc.public_subnets

  lifecycle { 
    ignore_changes = [desired_capacity, target_group_arns]
  }

  health_check_type    = "ELB"
}

resource "aws_autoscaling_policy" "scale-down" {
  name                   = "scale-down"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 120
}

resource "aws_cloudwatch_metric_alarm" "scale-down" {
  alarm_description   = "Monitors CPU utilization for Terramino ASG"
  alarm_actions       = [aws_autoscaling_policy.scale-down.arn]
  alarm_name          = "scale-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "10"
  evaluation_periods  = "2"
  period              = "120"
  statistic           = "Average"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_autoscaling_policy" "scale-up" {
  name                   = "scale-up"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 120
}

resource "aws_cloudwatch_metric_alarm" "scale-up" {
  alarm_description   = "Monitors CPU utilization for Terramino ASG"
  alarm_actions       = [aws_autoscaling_policy.scale-up.arn]
  alarm_name          = "scale-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "80"
  evaluation_periods  = "2"
  period              = "120"
  statistic           = "Average"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_lb" "lb" {
  name               = "my-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb-sg.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_listener" "lb-listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
}

resource "aws_lb_target_group" "target-group" {
  name     = "my-lb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_autoscaling_attachment" "as-attachment" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  lb_target_group_arn   = aws_lb_target_group.target-group.arn
}

resource "aws_security_group" "instance-sg" {
  name = "instance-sg"
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "instance-sg-ingress-rule" {
  from_port       = 80
  to_port         = 80
  ip_protocol     = "tcp"
  referenced_security_group_id = aws_security_group.lb-sg.id
  security_group_id = aws_security_group.instance-sg.id
}

resource "aws_vpc_security_group_egress_rule" "instance-sg-egress-rule" {
  from_port       = 0
  to_port         = 0
  ip_protocol     = "-1"
  cidr_ipv4       = "0.0.0.0/0"
  security_group_id = aws_security_group.instance-sg.id
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

output "lb_endpoint" {
  value = "http://${aws_lb.lb.dns_name}"
}

output "application_endpoint" {
  value = "http://${aws_lb.lb.dns_name}/index.php"
}

output "asg_name" {
  value = aws_autoscaling_group.asg.name
}

