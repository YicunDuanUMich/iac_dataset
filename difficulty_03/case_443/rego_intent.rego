package terraform.validation

# Set default validation states
default is_valid_dhcp_options = false

default is_valid_dhcp_options_association = false

# Validate aws_vpc_dhcp_options resource
is_valid_dhcp_options {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_vpc_dhcp_options"
        resource.expressions.tags.constant_value != null
}

# Validate aws_vpc_dhcp_options_association resource
is_valid_dhcp_options_association {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_vpc_dhcp_options_association"
        resource.expressions.dhcp_options_id.references[0] == "aws_vpc_dhcp_options.pike.id"
        resource.expressions.vpc_id != null
}
