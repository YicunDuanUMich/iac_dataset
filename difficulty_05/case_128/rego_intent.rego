package main

import future.keywords.in

default allow = false

allow {
    public_subnet_exists(input.resource_changes)
    private_subnet_exists(input.resource_changes)
    ec2_fleet_valid(input.resource_changes)
    launch_template_valid(input.resource_changes)
    scaling_group_valid(input.resource_changes)
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

ec2_fleet_valid(resources) {
    some resource in resources
    resource.type = "aws_ec2_fleet"
    resource.change.after.launch_template_config[0].launch_template_specification[0].version == "$Latest"
    resource.change.after.target_capacity_specification[0].on_demand_target_capacity == 5
    resource.change.after.target_capacity_specification[0].spot_target_capacity == 4
}

launch_template_valid(resources) {
    some resource in resources
    resource.type == "aws_launch_template"
    resource.change.after.image_id == "ami-0591e1c6a24d08458"
}

# scaling_group_valid(resources) {
#     some resource in resources
#     resource.type == "aws_autoscaling_group"
#     resource.change.after.launch_template[0].version == "$Latest"
# }