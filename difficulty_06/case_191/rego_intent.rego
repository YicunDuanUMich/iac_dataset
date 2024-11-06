package main

import future.keywords.in

default allow = false

# Check VPC exists with correct CIDR
vpc_exists {
    some i
    input.planned_values.root_module.resources[i].type == "aws_vpc"
    input.planned_values.root_module.resources[i].values.cidr_block == "10.0.0.0/16"
}

# Check private subnet 1 exists
private_subnet_1_exists {
    some i
    input.planned_values.root_module.resources[i].type == "aws_subnet"
    input.planned_values.root_module.resources[i].values.cidr_block == "10.0.1.0/24"
}

# Check private subnet 2 exists
private_subnet_2_exists {
    some i
    input.planned_values.root_module.resources[i].type == "aws_subnet"
    input.planned_values.root_module.resources[i].values.cidr_block == "10.0.2.0/24"
}

# Check EFS exists
efs_exists {
    some i
    input.planned_values.root_module.resources[i].type == "aws_efs_file_system"
}

aws_instances[resource] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    resource.change.after.ami == "ami-0230bd60aa48260c6"
}

# Aggregate all checks
allow {
    vpc_exists
    private_subnet_1_exists
    private_subnet_2_exists
    efs_exists
    count(aws_instances) == 2
}