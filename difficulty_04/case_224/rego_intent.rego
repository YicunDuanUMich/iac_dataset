package main

import future.keywords.in

default allow = false

# Check for DynamoDB table creation
dynamodb_global_table_created(resources) {
some resource in resources
resource.type == "aws_dynamodb_table"
resource.change.actions[_] == "create"
}

# Check if replicas match required regions exactly
replicas_valid(resource) {
resource.type == "aws_dynamodb_global_table"
resource.change.after.replica[0].region_name == "us-east-1"
resource.change.after.replica[1].region_name == "us-west-2"
}

# Aggregate checks for DynamoDB table creation with specific replicas
allow {
dynamodb_global_table_created(input.resource_changes)
some resource in input.resource_changes
replicas_valid(resource)
}