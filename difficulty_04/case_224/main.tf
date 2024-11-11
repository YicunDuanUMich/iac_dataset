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

resource "aws_dynamodb_table" "base_table" {
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "myAttribute"
  name             = "myTable"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "myAttribute"
    type = "S"
  }

  replica {
    region_name = "us-west-1"
  }

  replica {
    region_name = "us-west-2"
  }
}
