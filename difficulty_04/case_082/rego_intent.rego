package terraform.validation

default is_configuration_valid = false

default is_valid_r53_zone = false

default is_valid_r53_record_primary = false

default is_valid_r53_record_secondary = false

default is_valid_r53_health_check_primary = false

default is_valid_r53_health_check_secondary = false



# Validate aws_route53_zone resource
is_valid_r53_zone {
        some i
        resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_zone"

}

# Validate aws_route53_record
is_valid_r53_record_primary {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_record"
    resource.expressions.name
    resource.expressions.failover_routing_policy[0].type.constant_value == "PRIMARY"
    resource.expressions.type
    resource.expressions.ttl
    resource.expressions.records
    resource.expressions.set_identifier
    resource.expressions.zone_id.references[0] == "aws_route53_zone.main.zone_id"
    resource.expressions.health_check_id.references[0] == "aws_route53_health_check.primary_health_check.id"
}

is_valid_r53_record_secondary {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_record"
    resource.expressions.name
    resource.expressions.failover_routing_policy[0].type.constant_value == "SECONDARY"
    resource.expressions.type
    resource.expressions.ttl
    resource.expressions.records
    resource.expressions.set_identifier
    resource.expressions.zone_id.references[0] == "aws_route53_zone.main.zone_id"
    resource.expressions.health_check_id.references[0] == "aws_route53_health_check.secondary_health_check.id"

}

# Validate aws_route53_health_check
is_valid_r53_health_check_primary {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_health_check"
    resource.name == "primary_health_check"
    resource.expressions.fqdn
    resource.expressions.request_interval
    resource.expressions.type
}

is_valid_r53_health_check_secondary {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_health_check"
    resource.name == "secondary_health_check"
    resource.expressions.fqdn
    resource.expressions.request_interval
    resource.expressions.type
}


# Combine all checks into a final rule
is_configuration_valid {
    is_valid_r53_health_check_primary
    is_valid_r53_health_check_secondary
    is_valid_r53_zone
    is_valid_r53_record_primary
    is_valid_r53_record_secondary
}




