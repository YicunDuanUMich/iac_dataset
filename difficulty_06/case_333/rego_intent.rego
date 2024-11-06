package terraform.validation

default is_valid_db_instance = false

default is_valid_security_group = false

default is_valid_db_subnet_group = false

default is_valid_db_parameter_group = false

default is_valid_kms_key = false

# Validate aws_db_instance resource
is_valid_db_instance {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_db_instance"
        resource.expressions.allocated_storage.constant_value == 200
        resource.expressions.engine.constant_value == "postgres"
        resource.expressions.final_snapshot_identifier.constant_value == "pgsnapshot"
        resource.expressions.storage_encrypted.constant_value == true
}

# Validate aws_security_group resource
is_valid_security_group {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_security_group"
        count(resource.expressions.ingress) > 0
        count(resource.expressions.egress) > 0
}

# Validate aws_db_subnet_group resource
is_valid_db_subnet_group {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_db_subnet_group"
        count(resource.expressions.subnet_ids) > 0
}

# Validate aws_db_parameter_group resource
is_valid_db_parameter_group {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_db_parameter_group"
        # Additional checks for specific parameter values can be added here if needed
}

# Validate aws_kms_key resource
is_valid_kms_key {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_kms_key"
        # Additional checks for KMS key attributes can be added here if needed
}
