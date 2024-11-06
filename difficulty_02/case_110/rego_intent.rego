package terraform.validation

default has_s3_bucket = false

default has_s3_bucket_logging = false

default valid_configuration = false

has_s3_bucket {
    bucket := input.configuration.root_module.resources[_]
    bucket.type == "aws_s3_bucket"
    bucket.name == "a"
}

has_s3_bucket_logging {
    logging := input.configuration.root_module.resources[_]
    logging.type == "aws_s3_bucket_logging"
    logging.expression.bucket.constant_value == "a"
    logging.expression.target_bucket.constant_value == "logging-680235478471"
    logging.expression.target_prefix.constant_value == "log/"
}

valid_configuration {
    has_s3_bucket
    has_s3_bucket_logging
}
