terraform {
required_providers {
aws = {
source = "hashicorp/aws"
version = "~> 5.0"
}
}
}

resource "aws_iam_role" "example" {
name = "test_role"

# Terraform's "jsonencode" function converts a
# Terraform expression result to valid JSON syntax.
assume_role_policy = jsonencode({
Version = "2012-10-17"
Statement = [
{
Action = "sts:AssumeRole"
Effect = "Allow"
Sid = ""
Principal = {
Service = "dax.amazonaws.com"
}
},
]
})
}

resource "aws_dax_cluster" "bar" {
cluster_name = "cluster-example"
iam_role_arn = aws_iam_role.example.arn
node_type = "dax.r4.large"
replication_factor = 1
}