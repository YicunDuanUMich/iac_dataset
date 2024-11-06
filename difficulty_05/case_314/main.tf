provider "aws" {
  region = "us-west-1"
}

resource "aws_cloudwatch_event_rule" "cron" {
  description         = "Event rule that runs everyday at 7 UTC"
  schedule_expression = "cron(0 7 * * ? *)"

  role_arn = aws_iam_role.cron.arn
}

resource "aws_cloudwatch_event_target" "cron" {
  rule = aws_cloudwatch_event_rule.cron.name
  arn  = aws_lambda_function.cron.arn
}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_file = "cron.py"
  output_path = "cron.zip"
}

resource "aws_lambda_function" "cron" {
  function_name = "cron-lambda-function"
  role          = aws_iam_role.cron.arn

  filename = "cron.zip"
  handler  = "cron.lambda_handler"
  runtime  = "python3.12"
}

resource "aws_lambda_permission" "cron" {
  function_name = aws_lambda_function.cron.function_name
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron.arn
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