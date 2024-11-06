package main

import future.keywords.in

default allow = false

allow {
    public_subnet_exists(input.resource_changes)
    count(private_subnet_exists) == 2
    count(aws_instances) == 2
    rds_exist(input.resource_changes)
}

public_subnet_exists(resources) {
    some resource in resources
    resource.type == "aws_subnet"
    resource.change.after.map_public_ip_on_launch == true
}

private_subnet_exists[resource] {
    resource := input.resource_changes[_]
    resource.type == "aws_subnet"
    resource.change.after.map_public_ip_on_launch == false
}

rds_exist(resources) {
    some resource in resources
    resource.type == "aws_db_instance"
}

aws_instances[resource] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
}