package main

import future.keywords.in

default allow = false

aws_elasticache_user_valid(resources) {
    some resource in resources
    resource.type == "aws_elasticache_user"
    resource.change.after.engine == "REDIS"
}

# Aggregate all checks
allow {
    aws_elasticache_user_valid(input.resource_changes)
}