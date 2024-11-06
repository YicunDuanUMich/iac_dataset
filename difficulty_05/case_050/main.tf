provider "aws" {
  region = "us-west-2"
}

resource "aws_lambda_permission" "allow_lex_to_start_execution" {
  statement_id  = "AllowExecutionFromLex"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "lex.amazonaws.com"
}

resource "aws_lambda_function" "lambda_function" {
  function_name = "LexPizzaOrderFulfillment"
  handler       = "index.handler"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "nodejs18.x"
  filename      = "main.py.zip"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource aws_lex_intent "OrderPizza" {
  name = "OrderPizza"
      fulfillment_activity {
      type = "CodeHook"
      code_hook {
        uri            = aws_lambda_function.lambda_function.arn
        message_version = "1.0"
      }
    }
}

resource "aws_lex_bot" "order_pizza" {
  name     = "OrderPizza"
  description  = "Orders a pizza from a local pizzeria"
  
  idle_session_ttl_in_seconds = 600
  locale = "en-US"

  child_directed = false

  clarification_prompt {
    max_attempts = 2
    message {
      content      = "I didn't understand that, can you please repeat?"
      content_type = "PlainText"
    }
  }
  
  abort_statement {
    message {
      content      = "Sorry, I could not understand. Goodbye."
      content_type = "PlainText"
    }
  }
  
  voice_id = "Salli"
  process_behavior = "SAVE"
  
  intent {
    intent_name    = aws_lex_intent.OrderPizza.name
    intent_version = aws_lex_intent.OrderPizza.version
  }

  depends_on = [aws_lambda_permission.allow_lex_to_start_execution]
}