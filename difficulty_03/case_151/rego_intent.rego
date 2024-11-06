package main

import future.keywords.in

default allow = false

# Check for Lambda Function URL Resource
aws_lambda_invocation_valid(resources) {
    some resource in resources
    resource.type == "aws_lambda_invocation"
}

aws_lambda_function_valid(resources) {
    some resource in resources
    resource.type == "aws_lambda_function"
}

# Aggregate all checks
allow {
    aws_lambda_invocation_valid(input.resource_changes)
    aws_lambda_function_valid(input.resource_changes)
}