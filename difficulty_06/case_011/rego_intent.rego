package terraform.validation

default is_configuration_valid = false

default is_valid_iam_instance_profile = false

default is_valid_iam_role = false

default is_valid_iam_role_policy_attachment = false

default is_valid_s3_bucket = false

default is_valid_s3_object = false

default is_valid_eb_app = false

default is_valid_eb_env = false

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
    resource.expressions.records.references[0] == "aws_elastic_beanstalk_environment.eb-env.cname"
    resource.expressions.zone_id.references[0] == "aws_route53_zone.main.zone_id"

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
    resource.expressions.role.references[0] == "aws_iam_role.eb_ec2_role.name"
    resource.expressions.policy_arn.constant_value == "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

# Validate aws_iam_instance_profile resource
is_valid_iam_instance_profile {
                 some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_iam_instance_profile"
    resource.expressions.role.references[0] == "aws_iam_role.eb_ec2_role.name"
}

is_valid_s3_bucket {
                 some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_s3_bucket"
    resource.name
    # resource.expressions.bucket.constant_value == "sampleapril26426"
}

is_valid_s3_object {
                 some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_s3_object"
    # resource.expressions.bucket.references[0] == "aws_s3_bucket.sampleapril26426.id"
    resource.expressions.key
    resource.expressions.source
    
}

# Validate aws_eb_app
is_valid_eb_app {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_elastic_beanstalk_application"
    resource.expressions.name
}

is_valid_eb_app_version {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_elastic_beanstalk_application_version"
    resource.expressions.name
    resource.expressions.application.references[0] == "aws_elastic_beanstalk_application.myapp.name"
    resource.expressions.bucket.references[0] == "aws_s3_object.examplebucket_object.bucket"
    resource.expressions.key.references[0] == "aws_s3_object.examplebucket_object.key"
}
# Validate aws_eb_env
is_valid_eb_env {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_elastic_beanstalk_environment"
    resource.expressions.name
    resource.expressions.application.references[0] == "aws_elastic_beanstalk_application.myapp.name"
    resource.expressions.solution_stack_name
    resource.expressions.version_label.references[0] == "aws_elastic_beanstalk_application_version.version.name"
        some a
    resource.expressions.setting[a].value.references[0] == "aws_iam_instance_profile.eb_ec2_profile.name"
}


# Combine all checks into a final rule
is_configuration_valid {
        is_valid_iam_role
    is_valid_iam_role_policy_attachment
    is_valid_iam_instance_profile
        is_valid_r53_zone
        is_valid_r53_record
    is_valid_s3_bucket
    is_valid_s3_object 
    is_valid_eb_app_version
    is_valid_eb_app
    is_valid_eb_env
}