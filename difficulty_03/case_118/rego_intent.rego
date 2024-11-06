package terraform.validation

default has_aws_s3_bucket = false
default has_aws_s3_bucket_versioning = false
default has_aws_s3_bucket_object_lock_configuration = false

has_aws_s3_bucket {
    bucket := input.planned_values.root_module.resources[_]
    bucket.type == "aws_s3_bucket"
    bucket.name == "example"
    bucket.values.bucket == "mybucket"
}

has_aws_s3_bucket_versioning {
    versioning := input.planned_values.root_module.resources[_]
    versioning.type == "aws_s3_bucket_versioning"
    versioning.name == "example"
    versioning.values.bucket == input.planned_values.root_module.resources[_].values.id  # Correct bucket ID reference
    versioning.values.versioning_configuration.status == "Enabled"
}

has_aws_s3_bucket_object_lock_configuration {
    lock_config := input.planned_values.root_module.resources[_]
    lock_config.type == "aws_s3_bucket_object_lock_configuration"
    lock_config.name == "example"
    lock_config.values.bucket == input.planned_values.root_module.resources[_].values.id  # Correct bucket ID reference
    lock_config.values.rule.default_retention.mode == "COMPLIANCE"
    lock_config.values.rule.default_retention.days == 5
}

valid_configuration {
    has_aws_s3_bucket
    has_aws_s3_bucket_versioning
    has_aws_s3_bucket_object_lock_configuration
}
