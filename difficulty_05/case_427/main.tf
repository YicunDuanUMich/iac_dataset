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

locals {
  subnet_count = 2
}

resource "aws_vpc" "_" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "public" {
  count             = local.subnet_count
  vpc_id            = aws_vpc._.id
  cidr_block        = ["10.0.1.0/24",
                      "10.0.2.0/24",
                      "10.0.3.0/24",
                      "10.0.4.0/24"][count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
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
}

resource "aws_route_table_association" "public" {
  count          = local.subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}