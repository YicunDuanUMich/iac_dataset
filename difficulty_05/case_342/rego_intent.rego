package terraform.validation

default is_valid_db_instance = false

default is_valid_vpc = false

default is_valid_subnet = false

default is_valid_security_group = false

default is_valid_db_subnet_group = false

# Validate aws_db_instance resource
is_valid_db_instance {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_db_instance"
        resource.expressions.allocated_storage.constant_value == 20
        resource.expressions.engine.constant_value == "postgres"
        resource.expressions.engine_version.constant_value == "15.3"
        resource.expressions.instance_class.constant_value == "db.t4g.micro"
        resource.expressions.password.constant_value != null
        resource.expressions.username.constant_value != null
        resource.expressions.publicly_accessible.constant_value == true
        resource.expressions.db_subnet_group_name.references != null
        resource.expressions.vpc_security_group_ids.references != null
}

# Validate aws_vpc resource
is_valid_vpc {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_vpc"
        resource.expressions.cidr_block.constant_value != null
}

# Validate aws_subnet resource (more than one)
is_valid_subnet {
        count(subnets) > 1
}

subnets[resource] {
        resource := input.configuration.root_module.resources[_]
        resource.type == "aws_subnet"
}

# Validate aws_security_group resource
is_valid_security_group {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_security_group"
        # Additional checks for specific ingress/egress rules can be added here
}

# Validate aws_db_subnet_group resource
is_valid_db_subnet_group {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_db_subnet_group"
        count(resource.expressions.subnet_ids) > 0
}
