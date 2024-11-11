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

resource "aws_dynamodb_table" "caas" {
  name           = "cat_names"
  hash_key       = "name"
  billing_mode   = "PAY_PER_REQUEST"

  attribute {
    name = "name"
    type = "S"
  }
}

resource "aws_s3_bucket" "caas" {
  bucket_prefix = "cat-image"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_api_gateway_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_policy"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.caas.arn}/*"
      },
      {
        Action = [
          "dynamodb:PutItem"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.caas.arn
      }
    ]
  })
}

resource "aws_api_gateway_rest_api" "caas" {
  name = "caas"
}

resource "aws_api_gateway_resource" "caas_cat" {
  rest_api_id = aws_api_gateway_rest_api.caas.id
  parent_id   = aws_api_gateway_rest_api.caas.root_resource_id
  path_part   = "cat"
}

resource "aws_api_gateway_method" "caas_cat_get" {
  rest_api_id   = aws_api_gateway_rest_api.caas.id
  resource_id   = aws_api_gateway_resource.caas_cat.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "caas_cat_put" {
  rest_api_id   = aws_api_gateway_rest_api.caas.id
  resource_id   = aws_api_gateway_resource.caas_cat.id
  http_method   = "PUT"
  authorization = "NONE"
}

data "archive_file" "caas_cat" {
  type        = "zip"
  source_file = "./supplement/caas_cat.py"
  output_path = "./supplement/caas_cat.zip"
}

resource "aws_lambda_function" "caas_cat" {
  function_name = "caas_cat"
  role          = aws_iam_role.lambda_role.arn
  filename      = data.archive_file.caas_cat.output_path
  source_code_hash = data.archive_file.caas_cat.output_base64sha256
  handler       = "caas_cat.handler"
  runtime       = "python3.12"

  environment {
    variables = {
      CAAS_S3_BUCKET = "${aws_s3_bucket.caas.id}"
      DYNAMODB_TABLE_NAME = "${aws_dynamodb_table.caas.id}"
    }
  }
}

resource "aws_api_gateway_integration" "caas_cat_get" {
  rest_api_id             = aws_api_gateway_rest_api.caas.id
  resource_id             = aws_api_gateway_resource.caas_cat.id
  http_method             = aws_api_gateway_method.caas_cat_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "GET"
  uri                     = aws_lambda_function.caas_cat.invoke_arn
}

resource "aws_api_gateway_integration" "caas_cat_put" {
  rest_api_id             = aws_api_gateway_rest_api.caas.id
  resource_id             = aws_api_gateway_resource.caas_cat.id
  http_method             = aws_api_gateway_method.caas_cat_put.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "PUT"
  uri                     = aws_lambda_function.caas_cat.invoke_arn
}

resource "aws_lambda_permission" "caas_cat" {
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  function_name = aws_lambda_function.caas_cat.function_name

  source_arn = "${aws_api_gateway_rest_api.caas.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.caas.id
  depends_on  = [aws_api_gateway_integration.caas_cat_get, 
                 aws_api_gateway_integration.caas_cat_put]
}

resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.caas.id
  stage_name    = "dev"
}

output "api_id" {
  value = aws_api_gateway_rest_api.caas.id
  description = "The API Gateway ID"
}