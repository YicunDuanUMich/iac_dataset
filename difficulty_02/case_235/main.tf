resource "aws_vpc" "main" {
  cidr_block                       = "10.0.0.0/16"
}

resource "aws_egress_only_internet_gateway" "example_egress_igw" {
  vpc_id = aws_vpc.main.id
}