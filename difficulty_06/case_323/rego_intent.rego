package load_balancer

import rego.v1

default valid := false

instance_valid(instance, ami, key_pair) if {
        instance.expressions.instance_type.constant_value == "t2.micro"
        key_pair.address in instance.expressions.key_name.references
        ami.address in instance.expressions.ami.references
}

ami_valid(ami) if {
        some filter in ami.expressions.filter
        "al2023-ami-2023.*-x86_64" in filter.values.constant_value
        "amazon" in ami.expressions.owners.constant_value
}

lb_valid(lb, security_group, subnets) if {
        every subnet in subnets {
                subnet.address in lb.expressions.subnets.references
        }
        security_group.address in lb.expressions.security_groups.references
}

lb_listener_valid(lb_listener, lb, target_group) if {
        some default_action in lb_listener.expressions.default_action
        target_group.address in default_action.target_group_arn.references
        default_action.type.constant_value == "forward"
        lb.address in lb_listener.expressions.load_balancer_arn.references

        lb_listener.expressions.port.constant_value == 443
        lb_listener.expressions.protocol.constant_value == "HTTPS"
}

lb_target_group_valid(target_group, vpc) if {
        vpc.address in target_group.expressions.vpc_id.references

        target_group.expressions.port.constant_value == 443
        target_group.expressions.protocol.constant_value == "HTTPS"
}

lb_target_group_attachment_valid(target_group_attachment, target_group, instance) if {
        target_group.address in target_group_attachment.expressions.target_group_arn.references
        instance.address in target_group_attachment.expressions.target_id.references
}

lb_resources_valid(lb, lb_listener, target_group, target_group_attachment, instance, vpc, subnets, security_group) if {
        lb_valid(lb, security_group, subnets)
        lb_listener_valid(lb_listener, lb, target_group)
        lb_target_group_valid(target_group, vpc)
        lb_target_group_attachment_valid(target_group_attachment, target_group, instance)
}

route53_record_valid(record, zone, lb, type) if {
        zone.address in record.expressions.zone_id.references
        record.expressions.name.constant_value == "lb"
        record.expressions.type.constant_value == type
        some alias in record.expressions.alias
        lb.address in alias.zone_id.references
        lb.address in alias.name.references
        alias.evaluate_target_health.constant_value == true
}

route53_records_valid(records, zone, lb) if {
        some record_ipv4 in records
        route53_record_valid(record_ipv4, zone, lb, "A")
        some record_ipv6 in records
        route53_record_valid(record_ipv6, zone, lb, "AAAA")
}

route53_zone_valid(zone) if {
        zone.expressions.name.constant_value == "netflix.com"
}

s3_bucket_valid(s3_bucket) if {
        s3_bucket.expressions.bucket.constant_value == "video-content-bucket"
}

security_group_valid(security_group, vpc) if {
        vpc.address in security_group.expressions.vpc_id.references
}

subnet_valid(subnet, vpc, cidr) if {
        vpc.address in subnet.expressions.vpc_id.references
        subnet.expressions.cidr_block.constant_value == cidr
}

subnets_valid(subnets, vpc) if {
        some subnet_a in subnets
        subnet_valid(subnet_a, vpc, "10.0.1.0/24")
        some subnet_b in subnets
        subnet_valid(subnet_b, vpc, "10.0.2.0/24")
}

vpc_valid(vpc) if {
        vpc.expressions.cidr_block.constant_value == "10.0.0.0/16"
}

egress_rule_valid(egress_rule, security_group) if {
        egress_rule.expressions.cidr_ipv4.constant_value == "0.0.0.0/0"
        egress_rule.expressions.from_port.constant_value == 443
        egress_rule.expressions.to_port.constant_value == 443
        egress_rule.expressions.ip_protocol.constant_value == "tcp"
        security_group.address in egress_rule.expressions.security_group_id.references
}

ingress_rule_valid(ingress_rule, vpc, security_group) if {
        vpc.address in ingress_rule.expressions.cidr_ipv4.references
        ingress_rule.expressions.from_port.constant_value == 443
        ingress_rule.expressions.to_port.constant_value == 443
        ingress_rule.expressions.ip_protocol.constant_value == "tcp"
        security_group.address in ingress_rule.expressions.security_group_id.references
}

valid if {
        resources := input.configuration.root_module.resources
        some instance in resources
        instance.type == "aws_instance"
        some key_pair in resources
        key_pair.type == "aws_key_pair"
        some ami in resources
        ami.type == "aws_ami"

        some vpc in resources
        vpc.type == "aws_vpc"

        subnets := [subnet | subnet := resources[_]; subnet.type == "aws_subnet"]
        some security_group in resources
        security_group.type == "aws_security_group"
        some egress_rule in resources
        egress_rule.type == "aws_vpc_security_group_egress_rule"
        some ingress_rule in resources
        ingress_rule.type == "aws_vpc_security_group_ingress_rule"

        # lb resources
        some lb in resources
        lb.type == "aws_lb"
        some lb_listener in resources
        lb_listener.type == "aws_lb_listener"
        some target_group in resources
        target_group.type == "aws_lb_target_group"
        some target_group_attachment in resources
        target_group_attachment.type == "aws_lb_target_group_attachment"

        # route53
        records := [record | record := resources[_]; record.type == "aws_route53_record"]
        some zone in resources
        zone.type == "aws_route53_zone"

        # s3
        some s3_bucket in resources
        s3_bucket.type == "aws_s3_bucket"

        instance_valid(instance, ami, key_pair)
        ami_valid(ami)
        lb_resources_valid(lb, lb_listener, target_group, target_group_attachment, instance, vpc, subnets, security_group)
        route53_records_valid(records, zone, lb)
        route53_zone_valid(zone)
        s3_bucket_valid(s3_bucket)

        security_group_valid(security_group, vpc)

        subnets_valid(subnets, vpc)
        vpc_valid(vpc)
        egress_rule_valid(egress_rule, security_group)
        ingress_rule_valid(ingress_rule, vpc, security_group)
}