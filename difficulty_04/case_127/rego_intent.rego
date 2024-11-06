package main

import future.keywords.in

default allow = false

allow {
    count(aws_instances) == 2
    subnet_a_exists(input.resource_changes)
    subnet_b_exists(input.resource_changes)
}

aws_instances[resource] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    check_ami(resource)
    check_instance_type(resource)
    check_root_block_device(resource)
}

subnet_a_exists(resources) {
    some resource in resources
    resource.type == "aws_subnet"
    resource.change.after.availability_zone == "us-east-1a"
    resource.change.after.cidr_block == "10.0.1.0/24"
}

subnet_b_exists(resources) {
    some resource in resources
    resource.type == "aws_subnet"
    resource.change.after.availability_zone == "us-east-1b"
    resource.change.after.cidr_block == "10.0.2.0/24"
}

check_aws_instance(resources) {
    some resource in resources
    resource.type == "aws_instance"
    check_ami(resource)
    check_instance_type(resource)
    check_root_block_device(resource)
}

check_ami(aws_instance) {
    aws_instance.change.after.ami == "ami-0591e1c6a24d08458"
}

check_instance_type(aws_instance) {
    aws_instance.change.after.instance_type == "t2.micro"
}

check_root_block_device(aws_instance) {
    aws_instance.change.after.root_block_device[0].volume_size == 50
}