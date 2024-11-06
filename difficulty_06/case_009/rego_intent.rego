package terraform.validation

default is_configuration_valid = false

default is_valid_iam_instance_profile = false

default is_valid_iam_role = false

default is_valid_iam_role_policy_attachment = false

default is_valid_s3_bucket = false

default is_valid_s3_object = false

default is_valid_eb_app = false

default is_valid_eb_env = false

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
    resource.expressions.bucket.constant_value == "sampleapril26426"
}

is_valid_s3_object {
                 some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_s3_object"
    resource.expressions.bucket.references[0] == "aws_s3_bucket.sampleapril26426.id"
    resource.expressions.key
    resource.expressions.source
    
}

is_valid_sqs_queue {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_sqs_queue"
    resource.expressions.name
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
    resource.expressions.application.references[0] == "aws_elastic_beanstalk_application.batch_job_app.name"
    resource.expressions.bucket.references[0] == "aws_s3_object.examplebucket_object.bucket"
    resource.expressions.key.references[0] == "aws_s3_object.examplebucket_object.key"
}
# Validate aws_eb_env
is_valid_eb_env {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_elastic_beanstalk_environment"
    resource.expressions.name
    resource.expressions.application.references[0] == "aws_elastic_beanstalk_application.batch_job_app.name"
    resource.expressions.solution_stack_name
    resource.expressions.tier.constant_value == "Worker"
    resource.expressions.version_label.references[0] == "aws_elastic_beanstalk_application_version.version.name"
            some a, b
    resource.expressions.setting[a].value.references[0] == "aws_iam_instance_profile.eb_ec2_profile.name"
    resource.expressions.setting[b].value.references[0] == "aws_sqs_queue.batch_job_queue.id"
}


# Combine all checks into a final rule
is_configuration_valid {
        is_valid_iam_role
    is_valid_iam_role_policy_attachment
    is_valid_iam_instance_profile
    is_valid_s3_bucket
    is_valid_s3_object 
    is_valid_sqs_queue
    is_valid_eb_app_version
    is_valid_eb_app
    is_valid_eb_env
}
