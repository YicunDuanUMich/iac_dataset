package main

import future.keywords.in

default allow = false

# Check for IAM Role for Lambda
aws_iam_role_for_lambda_valid(resources) {
    some resource in resources
    resource.type == "aws_iam_role"
}

# Check for AWS Lambda Function with specific configurations
aws_lambda_function_valid(resources) {
    some resource in resources
    resource.type == "aws_lambda_function"
    resource.change.after.runtime == "nodejs18.x"
    resource.change.after.handler == "index.test"
    resource.change.after.filename == "lambda_function_payload.zip"
}

# Check for Archive File for Lambda code
archive_file_for_lambda_valid(resources) {
    some resource in resources
    resource.type == "archive_file"
    resource.values.source_file == "lambda.js"
    resource.values.type == "zip"
}

# Aggregate all checks
allow {
    aws_iam_role_for_lambda_valid(input.resource_changes)
    aws_lambda_function_valid(input.resource_changes)
    archive_file_for_lambda_valid(input.prior_state.values.root_module.resources)
}
