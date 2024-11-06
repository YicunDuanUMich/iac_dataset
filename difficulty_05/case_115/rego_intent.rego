package terraform.validation

default has_s3_bucket = false
default has_s3_bucket_acl = false
default has_s3_bucket_ownership_controls = false
default has_s3_bucket_public_access_block = false
default has_s3_bucket_policy = false
default valid_configuration = false

has_s3_bucket {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_s3_bucket"
    some i
    resource.expressions.bucket.references[i] == "local.bucket_suffix"
}


has_s3_bucket_acl {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_s3_bucket_acl"
    resource.values.acl != null
}

has_s3_bucket_ownership_controls {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_s3_bucket_ownership_controls"
    resource.values.rule[_].object_ownership != null
}


has_s3_bucket_public_access_block {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_s3_bucket_public_access_block"
    resource.values.block_public_acls == true
    resource.values.block_public_policy == false
    resource.values.ignore_public_acls == true
    resource.values.restrict_public_buckets == true
}

has_s3_bucket_policy {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_s3_bucket_policy"
    resource.expressions.policy.references != null
}


valid_configuration {
    has_s3_bucket
    has_s3_bucket_acl
    has_s3_bucket_ownership_controls
    has_s3_bucket_public_access_block
    has_s3_bucket_policy
}
