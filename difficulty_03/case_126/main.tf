provider "aws" {
  # Configure your AWS provider settings here
  region = "us-east-1"  # Update with your desired AWS region
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

resource "aws_instance" "example_instance" {
  ami           = data.aws_ami.latest_amazon_linux_2.id
  instance_type = "t3.2xlarge"  # Update with your desired instance type

  # Other instance configuration settings go here

  cpu_core_count = 2
  cpu_threads_per_core = 2
}