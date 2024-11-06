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

resource "aws_iam_role" "firehose_role2" {
  name               = "firehose_test_role2"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

resource "aws_s3_bucket" "januaryeleventh" {
  bucket = "januaryeleventh"
}
resource "aws_kinesis_firehose_delivery_stream" "test_stream" {
  name        = "terraform-kinesis-firehose-test-stream"
  destination = "http_endpoint"

  http_endpoint_configuration {
    url                = "https://aws-api.newrelic.com/firehose/v1"
    name               = "New Relic"
    access_key         = "my-key"
    buffering_size     = 15
    buffering_interval = 600
    role_arn           = aws_iam_role.firehose_role2.arn
    s3_backup_mode     = "FailedDataOnly"

    s3_configuration {
      role_arn           = aws_iam_role.firehose_role2.arn
      bucket_arn         = aws_s3_bucket.januaryeleventh.arn
      buffering_size     = 10
      buffering_interval = 400
      compression_format = "GZIP"
    }

    request_configuration {
      content_encoding = "GZIP"

      common_attributes {
        name  = "testname"
        value = "testvalue"
      }

      common_attributes {
        name  = "testname2"
        value = "testvalue2"
      }
    }
  }
}