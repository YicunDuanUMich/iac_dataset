terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}
# Define the provider block for AWS
provider "aws" {
  region = "us-east-2" # Set your desired AWS region
}

resource "aws_vpc" "_" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = merge({
    "Name" = "vpc"
  })
}

resource "aws_subnet" "public" {
  count             = 1
  vpc_id            = aws_vpc._.id
  cidr_block        = [
                      "10.0.1.0/24",
                      "10.0.2.0/24",
                      "10.0.3.0/24",
                      "10.0.4.0/24"
                    ][count.index]
  availability_zone = "us-west-2"
  tags = merge({
    "Name" = "public-subnet-${count.index}"
  })
}

resource "aws_internet_gateway" "_" {
  vpc_id = aws_vpc._.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc._.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway._.id
  }
  tags = merge({
    "Name" = "public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.public.id
}