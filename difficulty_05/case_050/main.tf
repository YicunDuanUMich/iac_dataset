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

resource "aws_lambda_permission" "allow_lex_to_start_execution" {
  statement_id  = "AllowExecutionFromLex"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_pizza.function_name
  principal     = "lex.amazonaws.com"
  # source_arn    = "${aws_lex_bot.order_pizza.arn}:$LATEST"
}

data "archive_file" "hello_pizza" {
  type        = "zip"
  source_file = "./supplement/hello_pizza.py"
  output_path = "./supplement/hello_pizza.zip"
}

resource "aws_lambda_function" "hello_pizza" {
  function_name = "hello_pizza"
  role          = aws_iam_role.iam_exec_role.arn
  filename      = data.archive_file.hello_pizza.output_path
  source_code_hash = data.archive_file.hello_pizza.output_base64sha256
  handler       = "hello_pizza.handler"
  runtime       = "python3.12"
}

resource "aws_iam_role" "iam_exec_role" {
  name = "iam-exec-role"
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

resource "aws_lex_intent" "OrderPizza" {
  name = "OrderPizza"

  sample_utterances = [
    "I would like to pick up a pizza",
    "I would like to order some pizzas",
  ]

  slot {
    name                     = "PizzaType"
    description              = "Type of pizza to order"
    slot_constraint          = "Required" 
    slot_type                = "AMAZON.AlphaNumeric"
    priority                 = 1
    value_elicitation_prompt {
      message {
        content             = "What type of pizza would you like?"
        content_type        = "PlainText"
      }
      max_attempts         = 2
    }
  }

  fulfillment_activity {
    type = "CodeHook"
    code_hook {
      uri            = aws_lambda_function.hello_pizza.arn
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

  voice_id = "Salli"
  process_behavior = "BUILD"

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
  
  intent {
    intent_name    = aws_lex_intent.OrderPizza.name
    intent_version = aws_lex_intent.OrderPizza.version
  }

  # depends_on = [aws_lambda_permission.allow_lex_to_start_execution]
}