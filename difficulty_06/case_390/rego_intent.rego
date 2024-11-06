package terraform.validation

default is_valid_vpc = false
default is_valid_subnet = false
default is_valid_lb = false
default is_valid_lb_listener = false
default is_valid_lb_target_group_attachment = false
default is_valid_lb_target_group = false
default is_valid_instance = false
default is_valid_security_group = false

# has one asw_lb resource
is_valid_lb {
    is_valid_app_lb
    has_valid_subnet
    has_valid_lb_argument
}

is_valid_app_lb {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_lb"
    resource.values.load_balancer_type == "application"
}

has_valid_subnet {
        resource := input.configuration.root_module.resources[_]
        resource.type == "aws_lb"
        resource.expressions.subnets
}

has_valid_lb_argument {
    	resource := input.configuration.root_module.resources[_]
        resource.type == "aws_lb"
        resource.expressions.enable_deletion_protection.constant_value == true
        resource.expressions.internal.constant_value == false
        resource.expressions.name.constant_value == "test-lb-tf"
        resource.expressions.security_groups.references != null
}

# has one vpc resource
is_valid_vpc {
    resource := input.configuration.root_module.resources[_]
    resource.expressions.cidr_block.constant_value != null
}

# has valid subnet
is_valid_subnet {
        resource := input.configuration.root_module.resources[_]
        resource.type == "aws_subnet"
        resource.expressions.vpc_id != null
        resource.expressions.cidr_block != null
}

# Validate aws_lb_listener with the required arguments
is_valid_lb_listener {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_lb_listener"
    resource.expressions.load_balancer_arn
    resource.expressions.default_action[0].type.constant_value == "forward"
    resource.expressions.default_action[0].target_group_arn != null
}


# if target type is instance, ip, or alb, should have protocol, port, and vpc_id
is_valid_lb_target_group {
    resources := input.planned_values.root_module.resources[_]
    resources.type == "aws_lb_target_group"
    valid_type := {"instance", "ip", "alb"}
    type := resources.values.target_type
    valid_type[type]
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_lb_target_group"
    resource.expressions.port != null
    resource.expressions.protocol != null
    resource.expressions.vpc_id != null
}

# Validate aws_lb_target_group_attachment with the required arguments
is_valid_lb_target_group_attachment {
        resource := input.configuration.root_module.resources[_]
        resource.type == "aws_lb_target_group_attachment"
        resource.expressions.target_group_arn
        resource.expressions.target_id
}

# Validate at least one aws_instance with the required arguments
is_valid_instance {
        count(valid_instances) > 0
}

valid_instances[instance] {
        instance := input.configuration.root_module.resources[_]
        instance.type == "aws_instance"
        requited_argument(instance)
}

requited_argument(instance) {
        instance.expressions.ami != null
        instance.expressions.instance_type != null
}

is_valid_security_group {
	resource := input.configuration.root_module.resources[_]
    resource.type == "aws_security_group"
}

# Aggregate validation
is_valid_configuration {
    is_valid_vpc
    is_valid_subnet
    is_valid_lb
    is_valid_lb_listener
    is_valid_lb_target_group_attachment
    is_valid_lb_target_group
    is_valid_instance
    is_valid_security_group
}