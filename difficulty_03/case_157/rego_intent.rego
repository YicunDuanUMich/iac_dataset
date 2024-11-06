package main

import future.keywords.in

default allow = false

# Check if AWS IAM Role for Lambda is being created
aws_iam_role_lambda_valid(resources) {
    some resource in resources
    resource.type == "aws_iam_role"
    contains(resource.change.after.assume_role_policy, "lambda.amazonaws.com")
}

# Check if AWS Lambda function is being created
aws_lambda_function_valid(resources) {
    some resource in resources
    resource.type == "aws_lambda_function"
    # Check for the specific file name and handler
}

# Aggregate all checks
allow {
    aws_iam_role_lambda_valid(input.resource_changes)
    aws_lambda_function_valid(input.resource_changes)
}