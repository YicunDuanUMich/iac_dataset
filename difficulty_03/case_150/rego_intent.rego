package main

import future.keywords.in

default allow = false

# Check for Lambda Function URL Resource
aws_lambda_function_url_valid(resources) {
    some resource in resources
    resource.type == "aws_lambda_function_url"
    resource.change.after.function_name == "lambda_function_name"
}

# Check for AWS Lambda Function named "example_lambda"
aws_lambda_function_example_lambda_valid(resources) {
    some resource in resources
    resource.type == "aws_lambda_function"
    resource.name == "example_lambda"
}

# Aggregate all checks
allow {
    aws_lambda_function_url_valid(input.resource_changes)
    aws_lambda_function_example_lambda_valid(input.resource_changes)
}