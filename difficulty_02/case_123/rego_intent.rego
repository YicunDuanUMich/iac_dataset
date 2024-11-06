package terraform.validation

default has_aws_s3_bucket_example = false
default has_aws_s3_bucket_ownership_controls_example = false

has_aws_s3_bucket_example {
    bucket := input.planned_values.root_module.resources[_]
    bucket.type == "aws_s3_bucket"
    bucket.name == "example"
    bucket.values.bucket == "example"
}

has_aws_s3_bucket_ownership_controls_example {
    controls := input.planned_values.root_module.resources[_]
    controls.type == "aws_s3_bucket_ownership_controls"
    controls.name == "example"
    controls.values.bucket == input.planned_values.root_module.resources[_].values.id  # Ensures it's the correct reference to "example" bucket
    controls.values.rule.object_ownership == "BucketOwnerPreferred"
}

valid_configuration {
    has_aws_s3_bucket_example
    has_aws_s3_bucket_ownership_controls_example
}
