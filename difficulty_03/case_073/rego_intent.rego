package terraform.validation

import future.keywords.in

default has_valid_resources = false

has_valid_iam_role(resources) { 
        some resource in resources 
    resource.type == "aws_iam_role" 
    contains(resource.change.after.assume_role_policy,"kinesisanalytics.amazonaws.com") 
}

has_valid_bucket {
    some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_s3_bucket"
}

has_valid_cloudwatch_log_group {
    some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_cloudwatch_log_group"
    resource.values.name
}

has_valid_cloudwatch_log_stream {
    some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_cloudwatch_log_stream"
    resource.values.name
    role := input.configuration.root_module.resources[i]
    role.expressions.log_group_name

}

has_valid_kinesis_analytics_application {
        some i
        resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_kinesis_analytics_application"
    resource.values.name
    resource.values.cloudwatch_logging_options
    
}

has_valid_resources {
	has_valid_bucket
    has_valid_iam_role(input.resource_changes)
    has_valid_cloudwatch_log_group
    has_valid_cloudwatch_log_stream
    has_valid_kinesis_analytics_application
}