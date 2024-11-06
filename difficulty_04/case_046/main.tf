provider "aws" {
  region = "us-east-1"
}

resource "aws_lex_intent" "BookTrip" {
  create_version = false
  description    = "Book a trip"
  name           = "BookTrip"
  fulfillment_activity {
    type = "ReturnIntent"
  }
}

resource "aws_lex_bot" "BookTripBot" {
  abort_statement {
    message {
      content      = "Sorry, I cannot assist you to book the trip right now."
      content_type = "PlainText"
    }
  }

  child_directed                = false
  clarification_prompt {
    max_attempts = 3

    message {
      content      = "I'm sorry, I didn't understand. Could you please repeat that?"
      content_type = "PlainText"
    }
  }

  create_version                = false
  description                   = "Bot for booking trips"
  idle_session_ttl_in_seconds   = 600
  locale                        = "en-US"
  name                          = "BookTripBot"
  process_behavior              = "SAVE"
  voice_id                      = "Salli"
  detect_sentiment = false
  enable_model_improvements = true
  nlu_intent_confidence_threshold = 0
  
  intent {
    intent_name    = aws_lex_intent.BookTrip.name
    intent_version = aws_lex_intent.BookTrip.version
  }
}