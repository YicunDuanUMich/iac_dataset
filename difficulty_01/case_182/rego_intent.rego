package main

import future.keywords.in

default allow = false

aws_sagemaker_human_task_ui_valid(resources) {
    some resource in resources
    resource.type == "aws_sagemaker_human_task_ui"
    resource.change.after.ui_template[0].content == "\u003ch1\u003e\n    TEST\n\u003c/h1\u003e"

}

# Aggregate all checks
allow {
    aws_sagemaker_human_task_ui_valid(input.resource_changes)
}