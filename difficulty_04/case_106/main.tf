provider "aws" {
    region = "us-west-1"
}

variable "backstage_bucket" {
  default = "backstage_bucket_for_my_corp"
}

variable "backstage_iam" {
  default = "backstage"
}

variable "shared_managed_tag" {
  default = "terraform_for_my_corp"
}

resource "aws_s3_bucket" "backstage" {
  bucket = "test-bucket"
  provider = aws

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name                   = var.backstage_bucket
    "Managed By Terraform" = var.shared_managed_tag
  }

}


resource "aws_s3_bucket_acl" "backstage_acl" {
  bucket = aws_s3_bucket.backstage.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backstage_server_side_encription" {
  bucket = aws_s3_bucket.backstage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backstage" {
  bucket = aws_s3_bucket.backstage.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}