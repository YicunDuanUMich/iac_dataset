package main

import future.keywords.in

default allow = false

# Check for CloudWatch event rule for EC2 CreateImage event
ec2_create_image_event_rule_valid(resources) {
    some resource in resources
    resource.type == "aws_cloudwatch_event_rule"
    contains(resource.change.after.event_pattern, "CreateImage")
    contains(resource.change.after.event_pattern, "ec2.amazonaws.com")
}

# Check for CloudWatch event target for triggering test_lambda
cloudwatch_event_target_for_lambda_valid(resources) {
    some resource in resources
    resource.type == "aws_cloudwatch_event_target"
    resource.change.after.rule == "EC2CreateImageEvent"
}

# Aggregate all checks
allow {
    ec2_create_image_event_rule_valid(input.resource_changes)
    cloudwatch_event_target_for_lambda_valid(input.resource_changes)
}