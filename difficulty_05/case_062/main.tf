provider "aws" {
  region = "us-east-1"
}

data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "firehose_role" {
  name               = "firehose_test_role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

resource "aws_s3_bucket" "januaryseventh" {
  bucket = "januaryseventh"
}

resource "aws_opensearch_domain" "test_cluster" {
  domain_name = "es-test-3"

  cluster_config {
    instance_count         = 2
    zone_awareness_enabled = true
    instance_type          = "m4.large.search"
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }
}

data "aws_iam_policy_document" "firehose-opensearch" {
  statement {
    effect  = "Allow"
    actions = ["es:*"]

    resources = [
      aws_opensearch_domain.test_cluster.arn,
      "${aws_opensearch_domain.test_cluster.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "firehose-opensearch" {
  name   = "opensearch"
  role   = aws_iam_role.firehose_role.id
  policy = data.aws_iam_policy_document.firehose-opensearch.json
}

resource "aws_kinesis_firehose_delivery_stream" "test" {
  depends_on = [aws_iam_role_policy.firehose-opensearch]

  name        = "terraform-kinesis-firehose-os"
  destination = "opensearch"

  opensearch_configuration {
    domain_arn = aws_opensearch_domain.test_cluster.arn
    role_arn   = aws_iam_role.firehose_role.arn
    index_name = "test"

    s3_configuration {
      role_arn   = aws_iam_role.firehose_role.arn
      bucket_arn = aws_s3_bucket.januaryseventh.arn
    }
  }
}