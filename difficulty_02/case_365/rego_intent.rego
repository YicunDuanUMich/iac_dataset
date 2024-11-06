package terraform.validation

default has_all_required_resources = false

# Rule for aws_lightsail_instance resource with specific arguments
has_valid_lightsail_instance {
    some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_lightsail_instance"
    resource.values.name
    resource.values.availability_zone
    resource.values.blueprint_id
    resource.values.bundle_id
    resource.values.key_pair_name
}

# Rule for aws_lightsail_key_pair resource with specific arguments
has_valid_lightsail_key_pair {
    some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_lightsail_key_pair"
    resource.values.name
    resource.values.public_key
}

# Combined rule to ensure both resources meet their respective conditions
has_all_required_resources {
    has_valid_lightsail_instance
    has_valid_lightsail_key_pair
}