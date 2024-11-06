package terraform.validation

default has_aws_kms_key = false
default has_aws_s3_bucket = false
default has_aws_s3_bucket_server_side_encryption_configuration = false

has_aws_kms_key {
    key := input.planned_values.root_module.resources[_]
    key.type == "aws_kms_key"
    key.name == "mykey"
    key.values.description == "This key is used to encrypt bucket objects"
    key.values.deletion_window_in_days == 10
}

has_aws_s3_bucket {
    bucket := input.planned_values.root_module.resources[_]
    bucket.type == "aws_s3_bucket"
    bucket.name == "mybucket"
    bucket.values.bucket == "mybucket"
}

has_aws_s3_bucket_server_side_encryption_configuration {
    encryption_config := input.planned_values.root_module.resources[_]
    encryption_config.type == "aws_s3_bucket_server_side_encryption_configuration"
    encryption_config.name == "example"
    encryption_config.values.bucket == input.planned_values.root_module.resources[_].values.id  # Correct bucket ID reference
    rule := encryption_config.values.rule.apply_server_side_encryption_by_default
    rule.kms_master_key_id == input.planned_values.root_module.resources[_].values.arn  # Correct KMS ARN reference
    rule.sse_algorithm == "aws:kms"
}

valid_configuration {
    has_aws_kms_key
    has_aws_s3_bucket
    has_aws_s3_bucket_server_side_encryption_configuration
}