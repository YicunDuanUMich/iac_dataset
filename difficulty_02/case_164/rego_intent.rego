package main

import future.keywords.in

default allow = false

# Check if AWS DynamoDB Kinesis Streaming Destination is being created for a specific table
aws_dynamodb_kinesis_streaming_destination_valid(resources) {
    some resource in resources
    resource.type == "aws_dynamodb_kinesis_streaming_destination"
}

# Aggregate all checks
allow {
    aws_dynamodb_kinesis_streaming_destination_valid(input.resource_changes)
}