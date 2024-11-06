provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "private-us-east-1a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Main"
  }
}

resource "aws_iam_role" "example" {
  name = "eks-cluster-1"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_eks_cluster" "example" {
  name     = "test"
  version  = "test-version"
  role_arn = aws_iam_role.example.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.private-us-east-1a.id,
    ]
  }
}

resource "aws_eks_access_entry" "example" {
  cluster_name      = aws_eks_cluster.example.name
  principal_arn     = aws_iam_role.example.arn
  kubernetes_groups = ["group-1", "group-2"]
  type              = "STANDARD"
}