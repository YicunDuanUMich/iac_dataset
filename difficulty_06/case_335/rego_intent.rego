package terraform.validation

default is_valid_db_instance = false

default is_valid_security_group = false

default is_valid_db_subnet_group = false

default is_valid_vpc = false

default is_valid_subnet = false

# Validate aws_db_instance resource
is_valid_db_instance {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_db_instance"
    resource.expressions.allocated_storage.constant_value == 5
    resource.expressions.instance_class.constant_value == "db.t3.micro"
        resource.expressions.engine.constant_value == "postgres"
        resource.expressions.engine_version.constant_value == "12.6"
        resource.expressions.instance_class.constant_value != null
        resource.expressions.password.constant_value != null
        resource.expressions.username.constant_value != null
        resource.expressions.publicly_accessible.constant_value == false
        resource.expressions.db_subnet_group_name.references != null
        resource.expressions.vpc_security_group_ids.references != null
}

# Validate aws_security_group resource
is_valid_security_group {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_security_group"
        # Ensure there are ingress and egress rules defined
        count(resource.expressions.ingress) > 0
        count(resource.expressions.egress) > 0
        # Additional conditions can be added to validate specific rules
}

# Validate aws_db_subnet_group resource
is_valid_db_subnet_group {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_db_subnet_group"
        count(resource.expressions.subnet_ids) > 0
}

# Validate aws_vpc resource
is_valid_vpc {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_vpc"
        resource.expressions.cidr_block.constant_value != null
}

# Validate aws_subnet resource
is_valid_subnet {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_subnet"
        resource.expressions.vpc_id.references != null
        # You can add additional conditions here to check for other attributes like cidr_block, map_public_ip_on_launch, etc.
}
