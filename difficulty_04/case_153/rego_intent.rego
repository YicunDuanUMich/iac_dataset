package main

import future.keywords.in

default allow = false

aws_dynamodb_table_valid(resources) {
    some resource in resources
    resource.type == "aws_dynamodb_table"
}

aws_lambda_function_valid(resources) {
    some resource in resources
    resource.type == "aws_lambda_function"
}

# Check for Lambda event source mapping from DynamoDB
aws_lambda_event_source_mapping_valid(resources) {
    some resource in resources
    resource.type == "aws_lambda_event_source_mapping"
}

# Aggregate all checks
allow {
    aws_dynamodb_table_valid(input.resource_changes)
    aws_lambda_function_valid(input.resource_changes)
    aws_lambda_event_source_mapping_valid(input.resource_changes)
}