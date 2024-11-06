package terraform.validation

default has_aws_s3_bucket_example = false
default has_aws_s3_bucket_acl_example = false
default has_aws_s3_bucket_log = false
default has_aws_s3_bucket_acl_log = false
default has_aws_s3_bucket_logging_example = false

has_aws_s3_bucket_example {
    bucket := input.planned_values.root_module.resources[_]
    bucket.type == "aws_s3_bucket"
    bucket.name == "example"
    bucket.values.bucket == "my-tf-example-bucket"
}

has_aws_s3_bucket_acl_example {
    acl := input.planned_values.root_module.resources[_]
    acl.type == "aws_s3_bucket_acl"
    acl.name == "example"
    acl.values.bucket == input.planned_values.root_module.resources[_].values.id  # Correct bucket ID reference
    acl.values.acl == "private"
}

has_aws_s3_bucket_log {
    bucket := input.planned_values.root_module.resources[_]
    bucket.type == "aws_s3_bucket"
    bucket.name == "log_bucket"
    bucket.values.bucket == "my-tf-log-bucket"
}

has_aws_s3_bucket_acl_log {
    acl := input.planned_values.root_module.resources[_]
    acl.type == "aws_s3_bucket_acl"
    acl.name == "log_bucket_acl"
    acl.values.bucket == input.planned_values.root_module.resources[_].values.id  # Correct bucket ID reference
    acl.values.acl == "log-delivery-write"
}

has_aws_s3_bucket_logging_example {
    logging := input.planned_values.root_module.resources[_]
    logging.type == "aws_s3_bucket_logging"
    logging.name == "example"
    logging.values.bucket == input.planned_values.root_module.resources[_].values.id  # Correct bucket ID reference for example bucket
    logging.values.target_bucket == input.planned_values.root_module.resources[_].values.id  # Correct bucket ID reference for log bucket
    logging.values.target_prefix == "log/"
}

valid_configuration {
    has_aws_s3_bucket_example
    has_aws_s3_bucket_acl_example
    has_aws_s3_bucket_log
    has_aws_s3_bucket_acl_log
    has_aws_s3_bucket_logging_example
}