provider "aws" {
  region = "us-west-2"
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

resource "aws_s3_bucket" "januarysixth" {
  bucket = "januarysixth"
}
resource "aws_opensearchserverless_security_policy" "example" {
  name = "example"
  type = "encryption"
  policy = jsonencode({
    "Rules" = [
      {
        "Resource" = [
          "collection/example"
        ],
        "ResourceType" = "collection"
      }
    ],
    "AWSOwnedKey" = true
  })
}

resource "aws_opensearchserverless_collection" "test_collection" {
  name = "example"
  depends_on = [aws_opensearchserverless_security_policy.example]
}

resource "aws_kinesis_firehose_delivery_stream" "test_stream" {
  name        = "terraform-kinesis-firehose-test-stream"
  destination = "opensearchserverless"

  opensearchserverless_configuration {
    collection_endpoint = aws_opensearchserverless_collection.test_collection.collection_endpoint
    role_arn            = aws_iam_role.firehose_role.arn
    index_name          = "test"

    s3_configuration {
      role_arn           = aws_iam_role.firehose_role.arn
      bucket_arn         = aws_s3_bucket.januarysixth.arn
      buffering_size     = 10
      buffering_interval = 400
      compression_format = "GZIP"
    }
  }
}