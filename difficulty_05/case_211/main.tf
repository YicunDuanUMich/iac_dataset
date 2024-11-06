terraform {
required_providers {
aws = {
source = "hashicorp/aws"
version = "~> 5.0"
}
}
}

# Configure the AWS Provider
provider "aws" {
region = "us-east-2"
}

resource "aws_vpc" "vpc" {
cidr_block = "192.168.0.0/22"
}

data "aws_availability_zones" "azs" {
state = "available"
}

resource "aws_subnet" "subnet_az1" {
availability_zone = data.aws_availability_zones.azs.names[0]
cidr_block = "192.168.0.0/24"
vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet_az2" {
availability_zone = data.aws_availability_zones.azs.names[1]
cidr_block = "192.168.1.0/24"
vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet_az3" {
availability_zone = data.aws_availability_zones.azs.names[2]
cidr_block = "192.168.2.0/24"
vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group" "sg" {
vpc_id = aws_vpc.vpc.id
}


resource "aws_msk_serverless_cluster" "example" {
cluster_name = "Example"

vpc_config {
subnet_ids = [aws_subnet.subnet_az1.id, aws_subnet.subnet_az2.id, aws_subnet.subnet_az3.id]
security_group_ids = [aws_security_group.sg.id]
}

client_authentication {
sasl {
iam {
enabled = true
}
}
}
}