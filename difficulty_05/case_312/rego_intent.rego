package job_scheduler_high

import rego.v1

lambda_permission_valid(lambda_permission, lambda, rule) if {
	lambda_permission.expressions.action.constant_value == "lambda:InvokeFunction"
	lambda_permission.expressions.principal.constant_value == "events.amazonaws.com"
	lambda.address in lambda_permission.expressions.function_name.references
	rule.address in lambda_permission.expressions.source_arn.references
}

target_valid(target, lambda, rule) if {
	lambda.address in target.expressions.arn.references
	rule.address in target.expressions.rule.references
}

lambda_valid(lambda, role) if {
	role.address in lambda.expressions.role.references
	lambda.expressions.function_name
	lambda.expressions.filename
	lambda.expressions.handler
	lambda.expressions.runtime
}

rule_valid(rule, role) if {
	role.address in rule.expressions.role_arn.references

	rule.expressions.schedule_expression.constant_value == "cron(0 7 * * ? *)"
}

default valid := false

valid if {
	resources := input.configuration.root_module.resources

	some rule in resources
	rule.type == "aws_cloudwatch_event_rule"

	some role in resources
	role.type == "aws_iam_role"

	some target in resources
	target.type == "aws_cloudwatch_event_target"

	some lambda in resources
	lambda.type == "aws_lambda_function"

	some lambda_permission in resources
	lambda_permission.type == "aws_lambda_permission"

	rule_valid(rule, role)
	lambda_valid(lambda, role)
	target_valid(target, lambda, rule)
	lambda_permission_valid(lambda_permission, lambda, rule)
}