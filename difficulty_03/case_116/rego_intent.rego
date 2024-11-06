package terraform.validation

default has_aws_s3_bucket = false
default has_aws_s3_bucket_acl = false
default has_aws_s3_bucket_policy = false
has_aws_s3_bucket {
    bucket := input.planned_values.root_module.resources[_]
    bucket.type == "aws_s3_bucket"
    bucket.name == "my_bucket"
    bucket.values.bucket == "my_unique_bucket_name"
}

has_aws_s3_bucket_acl {
    acl := input.planned_values.root_module.resources[_]
    acl.type == "aws_s3_bucket_acl"
    acl.name == "my_bucket_acl"
    acl.values.bucket == input.planned_values.root_module.resources[_].values.id  # Ensure correct bucket reference
    acl.values.acl == "private"
}

has_aws_s3_bucket_policy {
    policy := input.planned_values.root_module.resources[_]
    policy.type == "aws_s3_bucket_policy"
    policy.name == "my_bucket_policy"
    policy.values.bucket == input.planned_values.root_module.resources[_].values.id  # Ensure correct bucket reference
}

valid_configuration {
    has_aws_s3_bucket
    has_aws_s3_bucket_acl
    has_aws_s3_bucket_policy
}
