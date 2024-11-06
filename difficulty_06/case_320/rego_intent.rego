package load_balancer_high

import rego.v1

default valid := false

instance_valid(instance, ami) if {
	instance.expressions.instance_type
	ami.address in instance.expressions.ami.references
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
}

lb_target_group_valid(target_group, vpc) if {
	vpc.address in target_group.expressions.vpc_id.references
	target_group.expressions.port
	target_group.expressions.protocol
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

security_group_valid(security_group, vpc) if {
	vpc.address in security_group.expressions.vpc_id.references
}

subnet_valid(subnet, vpc) if {
	vpc.address in subnet.expressions.vpc_id.references
	subnet.expressions.cidr_block
}

subnets_valid(subnets, vpc) if {
	every subnet in subnets {
		subnet_valid(subnet, vpc)
	}
}

vpc_valid(vpc) if {
	vpc.expressions.cidr_block
}

valid if {
	resources := input.configuration.root_module.resources

	# ec2
	some instance in resources
	instance.type == "aws_instance"
	some ami in resources
	ami.type == "aws_ami"

	some vpc in resources
	vpc.type == "aws_vpc"

	subnets := [subnet | subnet := resources[_]; subnet.type == "aws_subnet"]
	count(subnets) > 1
	some security_group in resources
	security_group.type == "aws_security_group"

	# lb resources
	some lb in resources
	lb.type == "aws_lb"
	some lb_listener in resources
	lb_listener.type == "aws_lb_listener"
	some target_group in resources
	target_group.type == "aws_lb_target_group"
	some target_group_attachment in resources
	target_group_attachment.type == "aws_lb_target_group_attachment"

	# s3
	some s3_bucket in resources
	s3_bucket.type == "aws_s3_bucket"

	instance_valid(instance, ami)

	lb_resources_valid(lb, lb_listener, target_group, target_group_attachment, instance, vpc, subnets, security_group)
	security_group_valid(security_group, vpc)

	subnets_valid(subnets, vpc)
	vpc_valid(vpc)
}