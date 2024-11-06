package main

import future.keywords.in

default allow = false

# Check for VPC with public and private subnets
vpc_exists {
    some i
    input.resource_changes[i].type == "aws_vpc"
}

public_subnet_exists(resources) {
    some resource in resources
    resource.type == "aws_subnet"
    resource.change.after.map_public_ip_on_launch == true
}

private_subnet_exists(resources) {
    some resource in resources
    resource.type == "aws_subnet"
    resource.change.after.map_public_ip_on_launch == false
}

aws_instances[resource] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
}

# Aggregate all checks
allow {
    vpc_exists
    public_subnet_exists(input.resource_changes)
    private_subnet_exists(input.resource_changes)
    count(aws_instances) == 3
}