package main

import future.keywords.in

default allow = false


aws_sagemaker_code_repository_valid(resources) {
    some resource in resources
    resource.type == "aws_sagemaker_code_repository"
    resource.change.after.git_config[0].repository_url ==  "https://github.com/hashicorp/terraform-provider-aws.git"
}

# Aggregate all checks
allow {
    aws_sagemaker_code_repository_valid(input.resource_changes)
}