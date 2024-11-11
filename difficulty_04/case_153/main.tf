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

resource "aws_dynamodb_table" "example_table" {
  name           = "example_table"
  hash_key       = "id"
  read_capacity  = 10
  write_capacity = 10

  attribute {
    name = "id"
    type = "S"
  }

  # Enable DynamoDB Streams
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES" # Choose as per your requirement

  # Other configurations for your table
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "dynamodb_lambda_policy" {
  name   = "lambda-dynamodb-policy"
  role   = aws_iam_role.iam_for_lambda.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Sid": "AllowLambdaFunctionToCreateLogs",
        "Action": [ 
            "logs:*" 
        ],
        "Effect": "Allow",
        "Resource": [ 
            "arn:aws:logs:*:*:*" 
        ]
    },
    {
        "Sid": "AllowLambdaFunctionInvocation",
        "Effect": "Allow",
        "Action": [
            "lambda:InvokeFunction"
        ],
        "Resource": [
            "${aws_dynamodb_table.example_table.arn}/stream/*"
        ]
    },
    {
        "Sid": "APIAccessForDynamoDBStreams",
        "Effect": "Allow",
        "Action": [
            "dynamodb:GetRecords",
            "dynamodb:GetShardIterator",
            "dynamodb:DescribeStream",
            "dynamodb:ListStreams"
        ],
        "Resource": "${aws_dynamodb_table.example_table.arn}/stream/*"
    }
  ]
}
EOF
}

data "archive_file" "lambda_zip_file" {
  type        = "zip"
  source_file = "./supplement/app.js"
  output_path = "./supplement/app.zip"
}

resource "aws_lambda_function" "example_lambda" {
  filename      = data.archive_file.lambda_zip_file.output_path
  function_name = "lambda_app_function"
  source_code_hash = data.archive_file.lambda_zip_file.output_base64sha256
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "app.handler"
  runtime       = "nodejs18.x"
}

resource "aws_lambda_event_source_mapping" "dynamodb_lambda_mapping" {
  event_source_arn  = aws_dynamodb_table.example_table.stream_arn
  function_name     = aws_lambda_function.example_lambda.arn
  starting_position = "LATEST" # or "TRIM_HORIZON" as per your use case

}

output "dynamodb_arn" {
  value = aws_dynamodb_table.example_table.arn
  description = "The ARN of the DynamoDB table"
}

output "lambda_processing_arn" {
  value = aws_lambda_function.example_lambda.arn
  description = "The ARN of the Lambda function processing the DynamoDB stream"
}