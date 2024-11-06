provider "aws" {
    region = "us-west-1"
}

resource "aws_s3_bucket" "test" {
  bucket        = "metricbeat-test-bucket"
  force_destroy = true // Required for cleanup
}

resource "aws_s3_bucket_metric" "test" {
  bucket = aws_s3_bucket.test.id
  name   = "EntireBucket"
}

resource "aws_s3_bucket_object" "test" {
  key     = "someobject"
  bucket  = aws_s3_bucket.test.id
  content = "something"
}