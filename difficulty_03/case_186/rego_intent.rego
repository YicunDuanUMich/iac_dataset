package main

import future.keywords.in

default allow = false

allow {
    check_aws_instance(input.resource_changes)
}

check_aws_instance(resources) {
    some resource in resources
    resource.type == "aws_instance"
    check_ami(resource)
    check_cpu_options(resource)
}

check_ami(aws_instance) {
    aws_instance.change.after.ami == "ami-0591e1c6a24d08458"
}

check_cpu_options(aws_instance) {
	aws_instance.change.after.cpu_core_count==2
	aws_instance.change.after.cpu_threads_per_core==2
}