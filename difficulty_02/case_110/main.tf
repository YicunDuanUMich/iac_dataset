provider "aws" {
    region = "us-west-1"
}

resource "aws_s3_bucket" "a" {
  bucket = "testbucketineu-west2"
}

resource "aws_s3_bucket_logging" "example" {
  bucket        = "testbucketineu-west2"
  target_bucket = "logging-680235478471"
  target_prefix = "log/"
}