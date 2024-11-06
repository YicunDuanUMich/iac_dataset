package terraform.validation

default is_valid_db_instance = false
default is_valid_db_subnet_group = false
default is_valid_subnet = false
default is_valid_vpc = false

# Validate aws_db_instance resource
is_valid_db_instance {
    some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_db_instance"
    resource.expressions.allocated_storage.constant_value != null
    resource.expressions.engine.constant_value == "postgres"
    resource.expressions.instance_class.constant_value != null
    resource.expressions.password.constant_value != null  # Ensures password is set, potentially using a secure reference
    resource.expressions.username.constant_value != null
    resource.expressions.backup_retention_period.constant_value == 5
    resource.expressions.backup_window.constant_value == "03:00-06:00"
}

# Validate aws_db_subnet_group resource
is_valid_db_subnet_group {
    some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_db_subnet_group"
    count(resource.expressions.subnet_ids.references) > 0  # Ensures subnet IDs are specified
}

# Validate aws_subnet resource
is_valid_subnet {
    some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_subnet"
    resource.expressions.vpc_id.references != null  # Ensures the subnet is associated with a VPC
}

# Validate aws_vpc resource
is_valid_vpc {
    some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_vpc"
    resource.expressions.cidr_block.constant_value != null  # Ensures a CIDR block is specified for the VPC
}

