provider "aws" {
    region = "us-west-1"
}

resource "aws_s3_bucket" "example" {
  bucket = "example-bucket"
}

resource "aws_s3_bucket_object_lock_configuration" "example" {
  bucket = aws_s3_bucket.example.bucket

  rule {
    default_retention {
      mode  = "COMPLIANCE"
      days  = 30
    }
  }
}