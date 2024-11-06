package main

import future.keywords.in

default allow = false

aws_iam_role_valid(resources) {
    some resource in resources
    resource.type == "aws_iam_role"
}

aws_sagemaker_image_valid(resources) {
    some resource in resources
    resource.type == "aws_sagemaker_image"
}


# Aggregate all checks
allow {
    aws_sagemaker_image_valid(input.resource_changes)
    aws_iam_role_valid(input.resource_changes)
}