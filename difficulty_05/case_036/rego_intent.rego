package terraform.validation

import future.keywords.in

default has_valid_resources = false

# Rule for aws_iam_role resource
has_valid_iam_role(resources) { 
        some resource in resources 
    resource.type == "aws_iam_role" 
    contains(resource.change.after.assume_role_policy,"codebuild.amazonaws.com") 
} 

has_valid_codebuild {
        some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_codebuild_project"
        resource.values.artifacts[_].type != "NO_ARTIFACTS"
    resource.values.environment
    resource.values.name
    resource.values.cache
    resource.values.source[_].type == "GITHUB"
    role := input.configuration.root_module.resources[i]
    role.expressions.service_role
}

has_valid_bucket {
    some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_s3_bucket"
    
}


has_valid_resources {
        has_valid_iam_role(input.resource_changes)
    has_valid_codebuild
}