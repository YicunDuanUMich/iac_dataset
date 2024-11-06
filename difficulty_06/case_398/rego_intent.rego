package terraform.validation

default is_valid_configuration = false

# has one asw_lb resource
is_valid_lb {
        is_valid_app_lb
        has_valid_subnet
}

is_valid_app_lb {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_lb"
    resource.values.load_balancer_type == "application"
}

has_valid_subnet {
        resource := input.planned_values.root_module.resources[_]
        resource.type == "aws_lb"
        resource.values.subnet_mapping != null
}

has_valid_subnet {
        resource := input.configuration.root_module.resources[_]
        resource.type == "aws_lb"
        resource.expressions.subnets
}

# has one vpc resource
is_valid_vpc {
        have_required_vpc_argument
}

have_required_vpc_argument {
        resource := input.configuration.root_module.resources[_]
        resource.type == "aws_vpc"
        resource.expressions.cidr_block.constant_value != null
}

have_required_vpc_argument {
        resource := input.configuration.root_module.resources[_]
        resource.type == "aws_vpc"
        resource.expressions.ipv4_ipam_pool_id.constant_value != null
}

# has valid subnet
is_valid_subnet {
        resource := input.configuration.root_module.resources[_]
        resource.type == "aws_subnet"
        resource.expressions.vpc_id != null
        have_required_subnet_argument
}

have_required_subnet_argument {
        resource := input.configuration.root_module.resources[_]
        resource.type == "aws_subnet"
        resource.expressions.cidr_block != null
}

have_required_subnet_argument {
        resource := input.configuration.root_module.resources[_]
        resource.type == "aws_subnet"
        resource.expressions.ipv6_cider_block != null
}

is_valid_lb_listener {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_lb_listener"
    resource.expressions.load_balancer_arn
    
    default_action := resource.expressions.default_action[_]
    default_action.type.constant_value == "authenticate-cognito"
    
    authenticate_cognito := default_action.authenticate_cognito[_]
    authenticate_cognito.user_pool_arn.references[0] != null
    authenticate_cognito.user_pool_client_id.references[0] != null
    authenticate_cognito.user_pool_domain.references[0] != null 
}

is_valid_aws_cognito_user_pool {
         resource := input.configuration.root_module.resources[_]
    resource.type == "aws_cognito_user_pool"
    resource.expressions.name.constant_value != null
}

is_valid_aws_cognito_user_pool_client {
         resource := input.configuration.root_module.resources[_]
    resource.type == "aws_cognito_user_pool_client"
    resource.expressions.name.constant_value != null
    resource.expressions.user_pool_id.references != null
}

is_valid_aws_cognito_user_pool_domain {
         resource := input.configuration.root_module.resources[_]
    resource.type == "aws_cognito_user_pool_domain"
    resource.expressions.domain.constant_value != null
    resource.expressions.user_pool_id.references != null
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

is_valid_lb_target_group {
        resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_lb_listener"
    resource.values.target_type == "lambda"
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
        instance.expressions.launch_template != null
}

requited_argument(instance) {
        instance.expressions.ami != null
        instance.expressions.instance_type != null
}

# Aggregate validation
is_valid_configuration {
    is_valid_vpc
    is_valid_subnet
    is_valid_lb
    is_valid_lb_listener
    is_valid_aws_cognito_user_pool
    is_valid_aws_cognito_user_pool_client
    is_valid_aws_cognito_user_pool_domain
    is_valid_lb_target_group_attachment
        is_valid_lb_target_group
        is_valid_instance
}