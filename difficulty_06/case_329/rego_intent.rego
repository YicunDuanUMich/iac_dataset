package terraform.validation

default is_valid_vpc = false

default is_valid_subnet = false

default is_valid_security_group = false

default is_valid_db_instance = false

default is_valid_db_subnet_group = false

# Validate aws_vpc resource
is_valid_vpc {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_vpc"
        resource.expressions.cidr_block != null
        resource.expressions.enable_dns_hostnames.constant_value == true
        resource.expressions.tags != null
}

# Validate aws_subnet resource
is_valid_subnet {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_subnet"
        resource.expressions.vpc_id != null
        resource.expressions.cidr_block != null
        resource.expressions.tags != null
}

# Validate aws_security_group resource
is_valid_security_group {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_security_group"
        resource.expressions.vpc_id != null
        resource.expressions.ingress != null
        resource.expressions.egress != null
        resource.expressions.tags != null
}

# Validate aws_db_instance resource
is_valid_db_instance {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_db_instance"
        resource.expressions.allocated_storage.constant_value == 50
        resource.expressions.engine.constant_value == "mysql"
    resource.expressions.engine_version.constant_value == "5.7"
        resource.expressions.instance_class != null
        resource.expressions.username != null
        resource.expressions.password != null
        resource.expressions.skip_final_snapshot.constant_value == true
        resource.expressions.identifier.constant_value == "dolphinscheduler"
}

# Validate aws_db_subnet_group resource
is_valid_db_subnet_group {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_db_subnet_group"
        resource.expressions.subnet_ids != null
        count(resource.expressions.subnet_ids) > 0
}

# Helper function to ensure subnet_ids reference private subnets
private_subnet_ids(subnet_ids) {
        some i
        subnet := input.configuration.root_module.resources[i]
        subnet.type == "aws_subnet"
        subnet.expressions.tags.Type == "private"
        subnet.expressions.id == subnet_ids[_]
}
