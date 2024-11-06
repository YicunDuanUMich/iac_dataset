package terraform.validation 

import rego.v1

default is_valid_lb_listener = false
default is_valid_lb_target_group_attachment = false
default is_valid_lb_target_group = false
default is_valid_instance = false 

# Validate aws_lb_listener with the required arguments
is_valid_lb_listener if {
    some resource in input.configuration.root_module.resources
    resource.type == "aws_lb_listener"
    resource.expressions.default_action
    resource.expressions.load_balancer_arn
    resource.expressions.load_balancer_type.constant_value == "network"
}

# Validate aws_lb_target_group_attachment with the required arguments
is_valid_lb_target_group_attachment if {
    some resource in input.configuration.root_module.resources
    resource.type == "aws_lb_target_group_attachment"
    resource.expressions.target_group_arn
    resource.expressions.target_id
}

# Validate aws_lb_target_group exists
is_valid_lb_target_group if {
    some resource in input.configuration.root_module.resources
    resource.type == "aws_lb_target_group"
}

# Validate at least one aws_instance with the required arguments
is_valid_instance if {
    count(valid_instances) > 0
}

valid_instances[instance] if {
    some instance in input.configuration.root_module.resources
    instance.type == "aws_instance"
    requited_argument(instance)
}

requited_argument(instance) if {
    instance.expressions.ami.constant_value != null
    instance.expressions.instance_type.constant_value == "t2.micro"
}

# Aggregate validation
is_valid_configuration if {
    is_valid_lb_listener
    is_valid_lb_target_group_attachment
    is_valid_lb_target_group
    is_valid_instance
}