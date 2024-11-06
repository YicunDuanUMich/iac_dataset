resource "aws_s3_bucket" "example" {
  bucket = "example"
}

resource "aws_s3_bucket_metric" "example-entire-bucket" {
  bucket = aws_s3_bucket.example.id
  name   = "EntireBucket"
}