provider "aws" {
  region = "us-east-1"
}

resource "aws_lex_intent" "OrderPizza" {
  name = "OrderPizza"
  description = "Pizza order processing"
  fulfillment_activity {
    type = "ReturnIntent"
  }
}

resource "aws_lex_intent" "CancelOrder" {
  name = "CancelOrder"
  description = "Cancel an order"
  fulfillment_activity {
    type = "ReturnIntent"
  }
}

resource "aws_lex_intent" "CheckOrderStatus" {
  name = "CheckOrderStatus"
  description = "Check status of an order"
  fulfillment_activity {
    type = "ReturnIntent"
  }
}

resource "aws_lex_intent" "ModifyOrder" {
  name = "ModifyOrder"
  description = "Modify an existing order"
  fulfillment_activity {
    type = "ReturnIntent"
  }
}

resource "aws_lex_intent" "HelpOrder" {
  name = "HelpOrder"
  description = "Provide help for ordering"
  fulfillment_activity {
    type = "ReturnIntent"
  }
}

resource "aws_lex_bot" "PizzaOrderBot" {
  abort_statement {
    message {
      content      = "Sorry, I could not assist on this request."
      content_type = "PlainText"
    }
  }

  child_directed = false
  create_version = false
  idle_session_ttl_in_seconds = 600
  locale = "en-US"
  name = "PizzaOrderBot"
  process_behavior = "SAVE"
  voice_id = "Salli"
  detect_sentiment = false
  enable_model_improvements = false

  clarification_prompt {
    max_attempts = 2

    message {
      content      = "I'm sorry, I didn't understand the request. Can you reformulate?"
      content_type = "PlainText"
    }
  }

  intent {
    intent_name    = aws_lex_intent.OrderPizza.name
    intent_version = aws_lex_intent.OrderPizza.version
  }

  intent {
    intent_name    = aws_lex_intent.CancelOrder.name
    intent_version = aws_lex_intent.CancelOrder.version
  }

  intent {
    intent_name    = aws_lex_intent.CheckOrderStatus.name
    intent_version = aws_lex_intent.CheckOrderStatus.version
  }

  intent {
    intent_name    = aws_lex_intent.ModifyOrder.name
    intent_version = aws_lex_intent.ModifyOrder.version
  }

  intent {
    intent_name    = aws_lex_intent.HelpOrder.name
    intent_version = aws_lex_intent.HelpOrder.version
  }
}