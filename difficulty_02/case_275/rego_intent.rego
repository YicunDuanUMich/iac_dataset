package s3_bucket_metric
import future.keywords.in

default valid := false

valid {
    some bucket in input.configuration.root_module.resources
    bucket.type == "aws_s3_bucket"
    bucket.expressions.bucket.constant_value == "mybucket"
    
    some metrics in input.configuration.root_module.resources
    metrics.type == "aws_s3_bucket_metric"
    bucket.address in metrics.expressions.bucket.references
}

valid {
    some bucket in input.configuration.root_module.resources
    bucket.type == "aws_s3_bucket"
    bucket.expressions.bucket.constant_value == "mybucket"
    
    some metrics in input.configuration.root_module.resources
    metrics.type == "aws_s3_bucket_metric"
    metrics.expressions.bucket.constant_value == bucket.expressions.bucket.constant_value
}