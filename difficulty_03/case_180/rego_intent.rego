package main

import future.keywords.in

default allow = false

aws_iam_role_valid(resources) {
    some resource in resources
    resource.type == "aws_iam_role"
}

aws_sagemaker_code_repository_valid(resources) {
    some resource in resources
    resource.type == "aws_sagemaker_code_repository"
    resource.change.after.git_config[0].repository_url ==  "https://github.com/hashicorp/terraform-provider-aws.git"
}

aws_sagemaker_notebook_instance_valid(resources) {
    some resource in resources
    resource.type == "aws_sagemaker_notebook_instance"
    resource.change.after.default_code_repository != null
}

# Aggregate all checks
allow {
    aws_iam_role_valid(input.resource_changes)
    aws_sagemaker_code_repository_valid(input.resource_changes)
    aws_sagemaker_notebook_instance_valid(input.resource_changes)
}