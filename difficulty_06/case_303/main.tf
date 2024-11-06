provider "aws" {
  region = "us-west-1"
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

resource "aws_dynamodb_table" "caas" {
  name           = "cat_list"
  hash_key       = "name"
  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "name"
    type = "S"
  }
}

resource "aws_s3_bucket" "caas" {}

resource "aws_iam_role" "caas_read" {
  name = "test_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role" "caas_write" {
  name = "test_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_lambda_function" "caas_cat_get" {
  function_name = "caas_cat_get"
  role          = aws_iam_role.caas_read.arn
  filename      = "caas_cat_get.zip"
  handler       = "caas_cat_get.handler"
  runtime       = "python3.12"

  environment {
    variables = {
      CAAS_S3_BUCKET = "${aws_s3_bucket.caas.id}"
    }
  }
}

resource "aws_lambda_function" "caas_cat_put" {
  function_name = "caas_cat_put"
  role          = aws_iam_role.caas_write.arn
  filename      = "caas_cat_put.zip"
  handler       = "caas_cat_put.handler"
  runtime       = "python3.12"

  environment {
    variables = {
      CAAS_S3_BUCKET = "${aws_s3_bucket.caas.id}"
    }
  }
}

resource "aws_api_gateway_integration" "caas_cat_get" {
  rest_api_id             = aws_api_gateway_rest_api.caas.id
  resource_id             = aws_api_gateway_resource.caas_cat.id
  http_method             = aws_api_gateway_method.caas_cat_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "GET"
  uri                     = aws_lambda_function.caas_cat_get.invoke_arn
}

resource "aws_api_gateway_integration" "caas_cat_put" {
  rest_api_id             = aws_api_gateway_rest_api.caas.id
  resource_id             = aws_api_gateway_resource.caas_cat.id
  http_method             = aws_api_gateway_method.caas_cat_put.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "PUT"
  uri                     = aws_lambda_function.caas_cat_put.invoke_arn
}

resource "aws_lambda_permission" "caas_cat_get" {
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  function_name = aws_lambda_function.caas_cat_get.function_name

  source_arn = "${aws_api_gateway_rest_api.caas.execution_arn}/*/GET/cat"
}

resource "aws_lambda_permission" "caas_cat_put" {
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  function_name = aws_lambda_function.caas_cat_put.function_name

  source_arn = "${aws_api_gateway_rest_api.caas.execution_arn}/*/PUT/cat"
}