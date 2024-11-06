package terraform.validation

default has_aws_s3_bucket = false
default has_aws_s3_bucket_ownership_controls = false
default has_aws_s3_bucket_acl = false

has_aws_s3_bucket {
    bucket := input.planned_values.root_module.resources[_]
    bucket.type == "aws_s3_bucket"
    bucket.name == "example"
    bucket.values.bucket == "my-tf-example-bucket"
}

has_aws_s3_bucket_ownership_controls {
    ownership_controls := input.planned_values.root_module.resources[_]
    ownership_controls.type == "aws_s3_bucket_ownership_controls"
    ownership_controls.name == "example"
    ownership_controls.values.bucket == input.planned_values.root_module.resources[_].values.id  # Correct bucket ID reference
    ownership_controls.values.rule.object_ownership == "BucketOwnerPreferred"
}

has_aws_s3_bucket_acl {
    acl := input.planned_values.root_module.resources[_]
    acl.type == "aws_s3_bucket_acl"
    acl.name == "example"
    acl.values.bucket == input.planned_values.root_module.resources[_].values.id  # Correct bucket ID reference
    acl.values.acl == "private"
    dependency := acl.depends_on[_]
    dependency == "aws_s3_bucket_ownership_controls.example"
}

valid_configuration {
    has_aws_s3_bucket
    has_aws_s3_bucket_ownership_controls
    has_aws_s3_bucket_acl
}