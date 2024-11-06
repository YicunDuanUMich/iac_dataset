package caas_high

import rego.v1

api_valid(api) := true

cat_valid(cat, api) if {
	api.address in cat.expressions.parent_id.references
	api.address in cat.expressions.rest_api_id.references
}

method_valid(method, method_string, resource, api) if {
	method.expressions.http_method.constant_value == method_string
	resource.address in method.expressions.resource_id.references
	api.address in method.expressions.rest_api_id.references
	method.expressions.authorization
}

default valid := false

valid if {
	resources := input.configuration.root_module.resources

	some api in resources
	api.type == "aws_api_gateway_rest_api"

	some cat in resources
	cat.type == "aws_api_gateway_resource"

	some method_get in resources
	method_get.type == "aws_api_gateway_method"

	some method_put in resources
	method_put.type == "aws_api_gateway_method"

	some bucket in resources
	bucket.type == "aws_s3_bucket"

	api_valid(api)
	cat_valid(cat, api)
	method_valid(method_get, "GET", cat, api)
	method_valid(method_put, "PUT", cat, api)
}