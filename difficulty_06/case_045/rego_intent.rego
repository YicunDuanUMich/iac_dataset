package terraform.validation

import future.keywords.in

default has_valid_resources = false

# Rule for multiple aws_lex_intent resources
has_valid_lex_intents {
    count([intent | intent := input.planned_values.root_module.resources[_]; intent.type == "aws_lex_intent"; intent.values.name; intent.values.fulfillment_activity; intent.values.conclusion_statement; intent.values.follow_up_prompt == false])
}

# Rule for aws_lex_bot resource with specific arguments
has_valid_lex_bot_instance {
    some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_lex_bot"
    is_boolean(resource.values.child_directed)
    resource.values.clarification_prompt
    resource.values.abort_statement
    resource.values.name
}

# Combined rule to ensure all conditions are met
has_valid_resources {
    has_valid_lex_intents
    has_valid_lex_bot_instance
}