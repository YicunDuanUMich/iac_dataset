package terraform.validation

default is_valid_db_instance = false
default is_valid_security_group = false
default is_valid_random_string = false

# Validate aws_db_instance resource
is_valid_db_instance {
    some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_db_instance"
    resource.expressions.allocated_storage.constant_value != null
    resource.expressions.engine.constant_value == "mysql"
    # Ensure the instance class is valid; specific validation can be added based on requirements
    resource.expressions.instance_class.constant_value != null
    # Ensure the password is set; in real scenarios, ensure it's not hardcoded or ensure it's using a secure reference
    resource.expressions.password.references[0] != null
    resource.expressions.username.constant_value != null
    resource.expressions.publicly_accessible.constant_value == true
    resource.expressions.skip_final_snapshot.constant_value == false
}

# Validate aws_security_group resource
is_valid_security_group {
    some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_security_group"
    # Additional checks for specific ingress/egress rules can be added here
}

# Validate random_string resource for the database password
is_valid_random_string {
    some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "random_string"
    # Ensure the random_string is used for the db_instance password
    resource.name == "db_password"
}
