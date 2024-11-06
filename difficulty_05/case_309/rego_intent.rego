package cloud_desktop

import rego.v1

default valid := false

backup_plan_valid(backup_plan, backup_vault) if {
	# advanced_backup_setting
	some backup_setting in backup_plan.expressions.advanced_backup_setting
	backup_setting.backup_options.constant_value.WindowsVSS == "enabled"

	backup_setting.resource_type.constant_value == "EC2"

	# rule
	some rule in backup_plan.expressions.rule
	backup_vault.address in rule.target_vault_name.references
	some lifecycle in rule.lifecycle
	lifecycle.delete_after.constant_value == 7
	rule.schedule.constant_value == "cron(0 0 * * ? *)"
}

backup_selection_valid(backup_selection, backup_plan, instance) if {
	backup_plan.address in backup_selection.expressions.plan_id.references
	instance.address in backup_selection.expressions.resources.references
}

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

valid if {
	resources := input.configuration.root_module.resources
	some backup_plan in resources
	backup_plan.type == "aws_backup_plan"
	some backup_vault in resources
	backup_vault.type == "aws_backup_vault"
	some backup_selection in resources
	backup_selection.type == "aws_backup_selection"
	some instance in resources
	instance.type == "aws_instance"
	some key_pair in resources
	key_pair.type == "aws_key_pair"
	some ami in resources
	ami.type == "aws_ami"

	backup_plan_valid(backup_plan, backup_vault)
	backup_selection_valid(backup_selection, backup_plan, instance)
	instance_valid(instance, ami, key_pair)
	ami_valid(ami)
}