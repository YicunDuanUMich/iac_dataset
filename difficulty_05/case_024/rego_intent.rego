package terraform.validation

default is_configuration_valid = false

default is_valid_iam_instance_profile = false

default is_valid_iam_role = false

default is_valid_iam_role_policy_attachment = false

default is_valid_eb_app = false

default is_valid_eb_env = false

default is_valid_db_instance = false

default is_valid_r53_zone = false

default is_valid_r53_record = false



# Validate aws_route53_zone resource
is_valid_r53_zone {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_zone"
    resource.name
}

# Validate aws_route53_record
is_valid_r53_record {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_record"
    resource.expressions.name
    resource.expressions.type
    resource.expressions.ttl
    resource.expressions.records.references[0] == "aws_elastic_beanstalk_environment.myenv.cname"
    resource.expressions.zone_id.references[0]

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
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_elastic_beanstalk_environment"
    resource.expressions.name
    resource.expressions.application.references[0]
    resource.expressions.solution_stack_name
    some a, b, c, d
    resource.expressions.setting[a].value.references[0] == "aws_iam_instance_profile.eb_ec2_profile1.name"
    resource.expressions.setting[b].value.references[0] == "aws_db_instance.myapp_db.username"
    resource.expressions.setting[c].value.references[0] == "aws_db_instance.myapp_db.password"
    resource.expressions.setting[d].value.references[0] == "aws_db_instance.myapp_db.address"

}

is_valid_db_instance {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_db_instance"
    has_required_main_db_arguments
}

# Helper rule to check if all required arguments are present and valid
has_required_main_db_arguments {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_db_instance"
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
    is_valid_r53_zone
    is_valid_r53_record
}