package terraform.validation

default valid_configuration = false
default has_s3_bucket = false
default has_s3_bucket_metrix = false
default has_s3_bucket_object = false


# Check for if any aws_s3_bucket with "bucket"
has_s3_bucket {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_s3_bucket"
    resource.name == "my_bucket"
    resource.expressions.bucket.constant_value != null
}

has_s3_bucket_metrix{
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_s3_bucket_metric"
    resource.name == "my_bucket_matric"
    resource.expressions.bucket.references != null
    resource.expressions.name.constant_value != null
}

has_s3_bucket_object{
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_s3_bucket_object"
    resource.name == "my_bucket_object"
    reference_check(resource)
    resource.expressions.key.constant_value != null
}

reference_check(object){
	some i
    object.expressions.bucket.references[i] == "aws_s3_bucket.my_bucket.id"
}

valid_configuration{
    has_s3_bucket
    has_s3_bucket_metrix
    
}