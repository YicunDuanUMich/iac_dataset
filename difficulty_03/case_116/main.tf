provider "aws" {
    region = "us-west-1"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "my_unique_bucket_name"
}

resource "aws_s3_bucket_acl" "my_bucket_acl" {
  bucket = aws_s3_bucket.my_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "my_bucket_policy" {
  bucket = aws_s3_bucket.my_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "ExampleStatement1",
        Effect    = "Allow",
        Principal = "*",
        Action    = [
          "s3:GetObject"
        ],
        Resource = [
          "${aws_s3_bucket.my_bucket.arn}/*"
        ],
        Condition = {
          StringEquals = {
            "aws:Referer" = "http://www.example.com"
          }
        }
      }
    ]
  })
}