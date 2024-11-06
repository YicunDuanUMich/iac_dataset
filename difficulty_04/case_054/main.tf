provider "aws" {
  region = "us-west-2"
}




data "aws_region" "current" {}

resource "aws_connect_instance" "example" {
  identity_management_type = "CONNECT_MANAGED"
  inbound_calls_enabled    = true
  instance_alias           = "friendly-name-connect-13"
  outbound_calls_enabled   = true
}

resource "aws_lex_intent" "example" {
  create_version = true
  name           = "connect_lex_intent"
  fulfillment_activity {
    type = "ReturnIntent"
  }
  sample_utterances = [
    "I would like to pick up flowers.",
  ]
}

resource "aws_lex_bot" "example13" {
  abort_statement {
    message {
      content      = "Sorry, I am not able to assist at this time."
      content_type = "PlainText"
    }
  }
  clarification_prompt {
    max_attempts = 2
    message {
      content      = "I didn't understand you, what would you like to do?"
      content_type = "PlainText"
    }
  }
  intent {
    intent_name    = aws_lex_intent.example.name
    intent_version = "1"
  }

  child_directed   = true
  name             = "connect_lex_bot"
  process_behavior = "BUILD"
}

resource "aws_connect_bot_association" "example" {
  instance_id = aws_connect_instance.example.id
  lex_bot {
    lex_region = data.aws_region.current.name
    name       = aws_lex_bot.example13.name
  }
}
