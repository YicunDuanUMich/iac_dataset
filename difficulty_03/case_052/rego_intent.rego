package terraform.validation

import future.keywords.in

default has_valid_resources = false

# Rule for aws_iam_role resource
has_valid_iam_role(resources) { 
	some resource in resources 
    resource.type == "aws_iam_role" 
    contains(resource.change.after.assume_role_policy,"lex.amazonaws.com") 
} 

# Rule for aws_lex_bot resource with specific arguments
has_valid_lexv2models_bot_instance {
	some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_lexv2models_bot"
    resource.name
	resource.values.data_privacy[_].child_directed
    resource.values.idle_session_ttl_in_seconds
    role := input.configuration.root_module.resources[i]
    role.expressions.role_arn
}

# Combined rule to ensure all conditions are met
has_valid_resources {
    has_valid_iam_role(input.resource_changes)
    has_valid_lexv2models_bot_instance
}