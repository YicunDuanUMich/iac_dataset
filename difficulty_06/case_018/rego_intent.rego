package terraform.validation

default is_configuration_valid = false

default is_valid_iam_instance_profile = false

default is_valid_iam_role = false

default is_valid_iam_role_policy_attachment = false

default is_valid_eb_app = false

default is_valid_eb_env = false

default is_valid_db_instance = false

default is_valid_vpc = false

default is_valid_internet_gateway = false

default is_valid_subnet = false

default is_valid_subnet_group = false

default is_valid_security_group = false

default is_valid_route_table = false

default is_valid_route_table_association = false


is_valid_vpc {
		some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_vpc"
    resource.expressions.cidr_block
}

is_valid_internet_gateway {
			some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_internet_gateway"
    resource.expressions.vpc_id.references[0]
}

is_valid_subnet {
		some i, j
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_subnet"
    resource.expressions.cidr_block
    
    resource2 := input.configuration.root_module.resources[j]
    resource2.type == "aws_subnet"
    resource2.expressions.cidr_block
    resource2.expressions.vpc_id.references[0] == resource.expressions.vpc_id.references[0]

}

is_valid_subnet_group {
		some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_db_subnet_group"
    resource.expressions.subnet_ids.references[0]

}

is_valid_security_group {
		some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_security_group"
    resource.expressions.vpc_id.references[0]
    resource.expressions.egress
    resource.expressions.ingress
}

is_valid_route_table {
		some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route_table"
    resource.expressions.route.references[0]
    resource.expressions.vpc_id.references
}

is_valid_route_table_association {
		some i, j
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route_table_association"
    resource.expressions.subnet_id.references[0]
    resource.expressions.route_table_id.references[0]
    resource2 := input.configuration.root_module.resources[j]
    
    resource2.type == "aws_route_table_association"
    resource2.expressions.subnet_id.references[0]
    resource2.expressions.route_table_id.references[0]
    resource2.expressions.route_table_id.references[0] == resource.expressions.route_table_id.references[0]
    resource2.expressions.subnet_id.references[0] != resource.expressions.subnet_id.references[0]

}

is_valid_iam_role {
        some i
    resource := input.resource_changes[i]
    resource.type == "aws_iam_role"
    contains(resource.change.after.assume_role_policy,"ec2.amazonaws.com")
}

is_valid_iam_role_policy_attachment {
                 some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_iam_role_policy_attachment"
    resource.expressions.role.references[0]
    resource.expressions.policy_arn.constant_value == "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

# Validate aws_iam_instance_profile resource
is_valid_iam_instance_profile {
                 some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_iam_instance_profile"
    resource.expressions.role.references[0]
}

# Validate aws_eb_app
is_valid_eb_app {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_elastic_beanstalk_application"
    resource.expressions.name
}

# Validate aws_eb_env
is_valid_eb_env {
        some a
    resource := input.configuration.root_module.resources[a]
    resource.type == "aws_elastic_beanstalk_environment"
    resource.expressions.name
    resource.expressions.application.references[0]
    resource.expressions.solution_stack_name
    
    some c, d, e, f, g, h, i
    startswith(resource.expressions.setting[c].value.references[0], "aws_iam_instance_profile")
    endswith(resource.expressions.setting[c].value.references[0], "name")

    startswith(resource.expressions.setting[d].value.references[0], "aws_db_instance")
    endswith(resource.expressions.setting[d].value.references[0], "username")
    
    startswith(resource.expressions.setting[e].value.references[0], "aws_db_instance")
    endswith(resource.expressions.setting[e].value.references[0], "password")
    
    startswith(resource.expressions.setting[f].value.references[0], "aws_db_instance")
    endswith(resource.expressions.setting[f].value.references[0], "address")

    startswith(resource.expressions.setting[g].value.references[0], "aws_security_group")
    endswith(resource.expressions.setting[g].value.references[0], "id")
    
    startswith(resource.expressions.setting[h].value.references[0], "aws_vpc")
    endswith(resource.expressions.setting[h].value.references[0], "id")

    startswith(resource.expressions.setting[i].value.references[0], "aws_subnet")
    endswith(resource.expressions.setting[i].value.references[0], "id")
    
    startswith(resource.expressions.setting[i].value.references[2], "aws_subnet")
    endswith(resource.expressions.setting[i].value.references[2], "id")    
}

is_valid_db_instance {
                some i
        resource := input.configuration.root_module.resources[i]
    resource.type == "aws_db_instance"
    has_required_main_db_arguments
}

# Helper rule to check if all required arguments are present and valid
has_required_main_db_arguments {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_db_instance"
    resource.expressions.db_subnet_group_name.references[0]
    resource.expressions.vpc_security_group_ids.references[0]
    # Check for allocated_storage, engine, instance_class, username, password, and skip_final_snapshot
    requirement1(resource.expressions)
    # Check for instance_class validity
    requirement2(resource.expressions)
}



# 1, allocated_storage and engine or snapshot_identifier or replace_source_db
requirement1(expressions) {
    expressions.allocated_storage
    expressions.engine
    expressions.username
    expressions.password
    is_valid_engine(expressions.engine.constant_value)
}

requirement1(expressions) {
    expressions.snapshot_identifier
}

# Check for instance_class validity
requirement2(expressions) {
    expressions.instance_class
    is_valid_instance_class(expressions.instance_class.constant_value)
}


# Helper rule to validate engine value
is_valid_engine(engine) {
        engine_set := {
        "mysql",
        "postgres",
        "mariadb",
        "oracle-se",
        "oracle-se1",
        "oracle-se2",
        "oracle-ee",
        "sqlserver-ee",
        "sqlserver-se",
        "sqlserver-ex",
        "sqlserver-web"
    }
        engine_set[engine]
}

# Helper rule to validate instance class type
is_valid_instance_class(instance_class) {
        instance_class_starts_with(instance_class, "db.")
}

# Helper rule to check prefix of instance class
instance_class_starts_with(instance_class, prefix) {
        startswith(instance_class, prefix)
}


# Combine all checks into a final rule
is_configuration_valid {
        is_valid_iam_role
    is_valid_iam_role_policy_attachment
    is_valid_iam_instance_profile
    is_valid_eb_app
    is_valid_eb_env
    is_valid_db_instance
    is_valid_vpc
    is_valid_internet_gateway
    is_valid_subnet
    is_valid_subnet_group
    is_valid_security_group
    is_valid_route_table
    is_valid_route_table_association
    
}