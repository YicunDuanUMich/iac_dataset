provider "aws" {
  region = "us-east-1"
}

resource "aws_lex_bot" "pizza_order_bot" {
  create_version = false
  description = "Pizza order bot"
  idle_session_ttl_in_seconds = 600
  name = "PizzaOrderBot"

  child_directed = false

  abort_statement {
    message {
      content = "Sorry, I am not able to assist."
      content_type = "PlainText"
    }
  }

  clarification_prompt {
    max_attempts = 2
    message {
      content = "I'm sorry, I didn't understand that. Can you try again?"
      content_type = "PlainText"
    }
  }

  intent {
    intent_name = aws_lex_intent.OrderPizzaIntent.name
    intent_version = aws_lex_intent.OrderPizzaIntent.version
  }

  depends_on = [aws_lex_intent.OrderPizzaIntent]
}

resource "aws_lex_intent" "OrderPizzaIntent" {
  name = "OrderPizzaIntent"
  create_version = true

  slot {
    description = "Type of pizza to order"
    name = "PizzaType"
    priority = 0
    sample_utterances = ["I want a {PizzaType} pizza.", "A {PizzaType} pizza please."]
    slot_constraint = "Required"

    value_elicitation_prompt {
      max_attempts = 2
      message {
        content = "What type of pizza would you like to order?"
        content_type = "PlainText"
      }
    }

    slot_type = "AMAZON.AlphaNumeric"
  }

  confirmation_prompt {
    max_attempts = 2
    message {
      content = "So, you would like to order a pizza. Is that correct?"
      content_type = "PlainText"
    }
  }
  rejection_statement {
    message {
        content = "Sorry, I don't know how to help then"
        content_type = "PlainText"
      }
    }

  follow_up_prompt {
    prompt {
      max_attempts = 2
      message {
        content = "Would you like anything else with your order?"
        content_type = "PlainText"
      }
    }
    rejection_statement {
      message {
        content = "OK, Your pizza is on its way."
        content_type = "PlainText"
      }
    }
  }

  fulfillment_activity {
    type = "ReturnIntent"
  }

  depends_on = [aws_lex_slot_type.PizzaType]
}

resource "aws_lex_slot_type" "PizzaType" {
  create_version = true
  description = "Types of pizza available to order"
  name = "PizzaTypes"
  enumeration_value {
    value = "Margherita"
  }
  enumeration_value {
    value = "Pepperoni"
  }
}