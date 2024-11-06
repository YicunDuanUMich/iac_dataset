package aws_s3_object
import future.keywords.in

default valid := false

valid {
        some bucket in input.configuration.root_module.resources
        bucket.type == "aws_s3_bucket"

        some object in input.configuration.root_module.resources
        object.type == "aws_s3_object"
        object.expressions.bucket.constant_value == bucket.expressions.bucket.constant_value
        object.expressions.source.constant_value == "assets/test.pdf"
}

valid {
        some bucket in input.configuration.root_module.resources
        bucket.type == "aws_s3_bucket"

        some object in input.configuration.root_module.resources
        object.type == "aws_s3_object"
        bucket.address in object.expressions.bucket.references
        object.expressions.source.constant_value == "assets/test.pdf"
}