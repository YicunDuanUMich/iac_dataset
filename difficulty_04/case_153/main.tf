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

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "lambda.js"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "example_lambda" {
  filename      = "lambda_function_payload.zip"
  function_name = "lambda_function_name"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.test"

  runtime = "nodejs18.x"
}

resource "aws_lambda_event_source_mapping" "dynamodb_lambda_mapping" {
  event_source_arn  = aws_dynamodb_table.example_table.stream_arn
  function_name     = aws_lambda_function.example_lambda.arn
  starting_position = "LATEST" # or "TRIM_HORIZON" as per your use case

}

output "lambda_event_source_mapping_id" {
  value = aws_lambda_event_source_mapping.dynamodb_lambda_mapping.id
}