package s3_bucket_object
import future.keywords.in

default valid := false

valid {
        some bucket in input.configuration.root_module.resources
        bucket.type == "aws_s3_bucket"
        bucket.expressions.bucket.constant_value == "mybucket"

        some object in input.configuration.root_module.resources
        object.type == "aws_s3_bucket_object"
        bucket.address in object.expressions.bucket.references
        object.expressions.key
}

valid {
        some bucket in input.configuration.root_module.resources
        bucket.type == "aws_s3_bucket"
        bucket.expressions.bucket.constant_value == "mybucket"

        some object in input.configuration.root_module.resources
        object.type == "aws_s3_bucket_object"
        object.expressions.bucket.constant_value == bucket.expressions.bucket.constant_value
        object.expressions.key
}