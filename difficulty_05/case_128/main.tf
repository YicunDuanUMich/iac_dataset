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


data "aws_ami" "latest_amazon_linux_2" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Create Launch Template for EC2 instances
resource "aws_launch_template" "ec2_launch_template" {
  name = "my-launch-template"

  instance_type = "t2.micro"
  image_id = data.aws_ami.latest_amazon_linux_2.id
}

# Create EC2 Fleet
resource "aws_ec2_fleet" "ec2_fleet" {
  launch_template_config {
    launch_template_specification {
      launch_template_id = aws_launch_template.ec2_launch_template.id
      version            = "$Latest"
    }

  }

  target_capacity_specification {
    default_target_capacity_type = "on-demand"
    total_target_capacity        = 9
    on_demand_target_capacity    = 5
    spot_target_capacity         = 4
  }

  excess_capacity_termination_policy = "termination"

  replace_unhealthy_instances = true

  # Additional configurations can be added as needed
}

# Create EC2 Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  desired_capacity    = 1
  max_size            = 10
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]
  
  launch_template {
    id      = aws_launch_template.ec2_launch_template.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300

  # Additional configurations can be added as needed
}
