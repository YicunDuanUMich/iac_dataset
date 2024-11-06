package terraform.validation

default has_s3_bucket = false

default has_s3_bucket_acl = false

default has_s3_bucket_lifecycle_configuration_one = false

default has_s3_bucket_lifecycle_configuration_two = false

default has_s3_bucket_versioning = false

default valid_configuration = false

has_s3_bucket {
        bucket := input.planned_values.root_module.resources[_]
    bucket.type == "aws_s3_bucket"
        bucket.name == "wellcomecollection"
}

has_s3_bucket_acl {
        acl := input.planned_values.root_module.resources[_]
    acl.type == "aws_s3_bucket_acl"
        acl.values.acl == "private"
}

has_s3_bucket_lifecycle_configuration_one {
        lifecycle := input.planned_values.root_module.resources[_]
    lifecycle.type == "aws_s3_bucket_lifecycle_configuration"
        rule1 := lifecycle.values.rule[_]
        rule1.id != null
        rule1.status == "Enabled"
        rule1.expiration[_].days == 30
}

has_s3_bucket_lifecycle_configuration_two {
        lifecycle := input.planned_values.root_module.resources[_]
    lifecycle.type == "aws_s3_bucket_lifecycle_configuration"
        rule2 := lifecycle.values.rule[_]
        rule2.id != null
        rule2.status == "Enabled"
        rule2.noncurrent_version_expiration[_].noncurrent_days == 90
    rule2.transition[_].days == 30
    rule2.transition[_].storage_class == "STANDARD_IA"
}

has_s3_bucket_versioning {
    versioning := input.planned_values.root_module.resources[_]
    versioning.type == "aws_s3_bucket_versioning"
    versioning.values.versioning_configuration[_].status == "Enabled"
}

valid_configuration {
        has_s3_bucket
        has_s3_bucket_acl
        has_s3_bucket_lifecycle_configuration_one
    has_s3_bucket_lifecycle_configuration_two
        has_s3_bucket_versioning
}
