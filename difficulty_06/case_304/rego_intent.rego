package caas_middle

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
}

table_valid(table) if {
	some attribute in table.expressions.attribute
	attribute.name
	attribute.type

	table.expressions.hash_key
}

lambda_valid(lambda, bucket) if {
	some env in lambda.expressions.environment
	bucket.address in env.variables.references
}

permission_valid(permission, lambda, api) if {
	permission.expressions.action.constant_value == "lambda:InvokeFunction"
	lambda.address in permission.expressions.function_name.references
	permission.expressions.principal.constant_value == "apigateway.amazonaws.com"
	api.address in permission.expressions.source_arn.references
}

integration_valid(integration, lambda, method, resource, api, integration_method) if {
	method.address in integration.expressions.http_method.references
	resource.address in integration.expressions.resource_id.references
	api.address in integration.expressions.rest_api_id.references
	integration.expressions.integration_http_method.constant_value == integration_method
	integration.expressions.type.constant_value == "AWS_PROXY"
	lambda.address in integration.expressions.uri.references
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

	some table in resources
	table.type == "aws_dynamodb_table"

	some lambda_get in resources
	lambda_get.type == "aws_lambda_function"

	some lambda_put in resources
	lambda_put.type == "aws_lambda_function"

	some bucket in resources
	bucket.type == "aws_s3_bucket"

	some permission_get in resources
	permission_get.type == "aws_lambda_permission"

	some permission_put in resources
	permission_put.type == "aws_lambda_permission"

	some integration_get in resources
	integration_get.type == "aws_api_gateway_integration"

	some integration_put in resources
	integration_put.type == "aws_api_gateway_integration"

	api_valid(api)
	cat_valid(cat, api)
	method_valid(method_get, "GET", cat, api)
	method_valid(method_put, "PUT", cat, api)
	lambda_valid(lambda_get, bucket, archive_get)
	lambda_valid(lambda_put, bucket, archive_put)
	permission_valid(permission_get, lambda_get, api)
	permission_valid(permission_put, lambda_put, api)
	integration_valid(integration_get, lambda_get, method_get, cat, api, "GET")
	integration_valid(integration_put, lambda_put, method_put, cat, api, "PUT")
}