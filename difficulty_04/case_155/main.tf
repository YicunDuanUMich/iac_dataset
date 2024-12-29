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
  region = "us-east-1"
  profile = "admin-1"

  assume_role {
    role_arn = "arn:aws:iam::590184057477:role/yicun-iac"
  }
}

resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  name        = "lambda-schedule-rule"
  description = "Invoke Lambda function every 15 minutes"
  schedule_expression = "rate(15 minutes)"
  role_arn = aws_iam_role.cron.arn
}

# Create a CloudWatch Events Target to associate with the Lambda function
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule = aws_cloudwatch_event_rule.lambda_schedule.name
  arn = aws_lambda_function.cron.arn
}

data "archive_file" "lambda-func" {
  type        = "zip"
  source_file = "./supplement/lambda_func.py"
  output_path = "./supplement/lambda_func.zip"
}

resource "aws_lambda_function" "cron" {
  function_name = "cron-lambda-function"
  role          = aws_iam_role.cron.arn
  filename      = data.archive_file.lambda-func.output_path
  source_code_hash = data.archive_file.lambda-func.output_base64sha256
  handler       = "lambda_func.handler"
  runtime       = "python3.12"
}

resource "aws_lambda_permission" "cron" {
  function_name = aws_lambda_function.cron.function_name
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_schedule.arn
}

data "aws_iam_policy_document" "cron_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "events.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "cron" {
  name               = "cron_assume_role"
  assume_role_policy = data.aws_iam_policy_document.cron_assume_role.json
}

resource "aws_iam_role_policy_attachment" "cron" {
  role       = aws_iam_role.cron.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
