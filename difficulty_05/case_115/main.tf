terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.75"
    }
  }

  required_version = "~> 1.9.8"
}

provider "aws" {
  region  = "us-east-1"
  profile = "admin-1"

  assume_role {
    role_arn = "arn:aws:iam::590184057477:role/yicun-iac"
  }
}

# Bucket Name Suffix
locals {
  bucket_suffix = "test"
}

#S3 Bucket glue-final
resource "aws_s3_bucket" "cg-data-s3-bucket" {
  bucket        = "cg-data-s3-bucket-${local.bucket_suffix}"
  force_destroy = true
}


# ACL is outdated (https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html)
# resource "aws_s3_bucket_acl" "cg-data-s3-bucket-acl" {
#   bucket     = aws_s3_bucket.cg-data-s3-bucket.id
#   acl        = "private"
#   depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
# }

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.cg-data-s3-bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# web to s3
# test-glue-scenario2
resource "aws_s3_bucket" "cg-data-from-web" {
  bucket        = "cg-data-from-web-${local.bucket_suffix}"
  force_destroy = true
}

resource "aws_s3_object" "web-data-primary" {
  bucket = aws_s3_bucket.cg-data-from-web.id
  key    = "order_data2.csv"
  source = "./supplement/order_data2.csv"
  # acl    = "bucket-owner-full-control"
}


resource "aws_s3_bucket_public_access_block" "access_block" {
  bucket = aws_s3_bucket.cg-data-from-web.id

  ignore_public_acls      = true
  block_public_acls       = true
  block_public_policy     = false
  restrict_public_buckets = true
}


resource "aws_s3_bucket_policy" "put_object" {
  bucket = aws_s3_bucket.cg-data-from-web.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Statement1"
        Action    = ["s3:PutObject"]
        Effect    = "Allow"
        Resource  = "${aws_s3_bucket.cg-data-from-web.arn}/*"
        Principal = "*"
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.access_block]
}