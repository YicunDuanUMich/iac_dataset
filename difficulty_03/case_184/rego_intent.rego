package main

import future.keywords.in

default allow = false

aws_iam_role_valid(resources) {
    some resource in resources
    resource.type == "aws_iam_role"
}

aws_sagemaker_model_valid(resources) {
    some resource in resources
    resource.type == "aws_sagemaker_model"
}

aws_sagemaker_endpoint_configuration_valid(resources) {
    some resource in resources
    resource.type == "aws_sagemaker_endpoint_configuration"
}

aws_sagemaker_endpoint_valid(resources) {
    some resource in resources
    resource.type == "aws_sagemaker_endpoint"
}

# Aggregate all checks
allow {
    aws_iam_role_valid(input.resource_changes)
    aws_sagemaker_model_valid(input.resource_changes)
    aws_sagemaker_endpoint_configuration_valid(input.resource_changes)
    aws_sagemaker_endpoint_valid(input.resource_changes)
}