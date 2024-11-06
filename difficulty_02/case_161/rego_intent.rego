package main

import future.keywords.in

default allow = false

# Check if AWS CloudWatch Composite Alarm is being created
aws_cloudwatch_composite_alarm_valid(resources) {
    some resource in resources
    resource.type == "aws_cloudwatch_metric_alarm"
    resource.change.after.comparison_operator == "GreaterThanOrEqualToThreshold"
    resource.change.after.threshold == 80
    resource.change.after.evaluation_periods == 2
}

# Aggregate all checks
allow {
    aws_cloudwatch_composite_alarm_valid(input.resource_changes)
}
