package aws_neptune_cluster
import future.keywords.in

default valid := false

# See for more info: https://docs.aws.amazon.com/neptune/latest/userguide/parameter-groups.html
default cluster_parameter_group_valid := false
default instance_parameter_group_valid := false

valid {
    some vpc in input.configuration.root_module.resources
    vpc.type == "aws_vpc"
 
    some subnet1 in input.configuration.root_module.resources
    subnet1.type == "aws_subnet"
    vpc.address in subnet1.expressions.vpc_id.references
    
    some subnet2 in input.configuration.root_module.resources
    subnet2.type == "aws_subnet"
    vpc.address in subnet2.expressions.vpc_id.references
    
    not subnet1 == subnet2
    
    some subnet_group in input.configuration.root_module.resources
    subnet_group.type == "aws_neptune_subnet_group"
    subnet1.address in subnet_group.expressions.subnet_ids.references
    subnet2.address in subnet_group.expressions.subnet_ids.references
    
    some cluster in input.configuration.root_module.resources
    cluster.type == "aws_neptune_cluster"
    cluster_parameter_group_valid
    subnet_group.address in cluster.expressions.neptune_subnet_group_name.references
    
    some instance in input.configuration.root_module.resources
    instance.type == "aws_neptune_cluster_instance"
    cluster.address in instance.expressions.cluster_identifier.references
    instance_parameter_group_valid
}


cluster_parameter_group_valid {
    some cluster in input.configuration.root_module.resources
    cluster.type == "aws_neptune_cluster"

    some cluster_parameter_group in input.configuration.root_module.resources
    cluster_parameter_group.type == "aws_neptune_cluster_parameter_group"
    cluster_parameter_group.address in cluster.expressions.neptune_cluster_parameter_group_name.references

    cluster.expressions.engine_version.constant_value < "1.2.0.0"
    cluster_parameter_group.expressions.family.constant_value == "neptune1"   
}

cluster_parameter_group_valid {
    some cluster in input.configuration.root_module.resources
    cluster.type == "aws_neptune_cluster"

    some cluster_parameter_group in input.configuration.root_module.resources
    cluster_parameter_group.type == "aws_neptune_cluster_parameter_group"
    cluster_parameter_group.address in cluster.expressions.neptune_cluster_parameter_group_name.references

    cluster.expressions.engine_version.constant_value >= "1.2.0.0"
    cluster_parameter_group.expressions.family.constant_value == "neptune1.2"   
}

cluster_parameter_group_valid {
    some cluster in input.configuration.root_module.resources
    cluster.type == "aws_neptune_cluster"
    
    some cluster_parameter_group in input.configuration.root_module.resources
    cluster_parameter_group.type == "aws_neptune_cluster_parameter_group"
    cluster_parameter_group.address in cluster.expressions.neptune_cluster_parameter_group_name.references
    
    not cluster.expressions.engine_version.constant_value # defaults as latest version
    cluster_parameter_group.expressions.family.constant_value == "neptune1.2"   
}

instance_parameter_group_valid {
    some instance in input.configuration.root_module.resources
    instance.type == "aws_neptune_cluster_instance"

    some instance_parameter_group in input.configuration.root_module.resources
    instance_parameter_group.type == "aws_neptune_parameter_group"
    instance_parameter_group.address in instance.expressions.neptune_parameter_group_name.references

    instance.expressions.engine_version.constant_value < "1.2.0.0"
    instance_parameter_group.expressions.family.constant_value == "neptune1"
}

instance_parameter_group_valid {
    some instance in input.configuration.root_module.resources
    instance.type == "aws_neptune_cluster_instance"

    some instance_parameter_group in input.configuration.root_module.resources
    instance_parameter_group.type == "aws_neptune_parameter_group"
    instance_parameter_group.address in instance.expressions.neptune_parameter_group_name.references

    instance.expressions.engine_version.constant_value >= "1.2.0.0"
    instance_parameter_group.expressions.family.constant_value == "neptune1.2"
}

instance_parameter_group_valid {
    some instance in input.configuration.root_module.resources
    instance.type == "aws_neptune_cluster_instance"

    some instance_parameter_group in input.configuration.root_module.resources
    instance_parameter_group.type == "aws_neptune_parameter_group"
    instance_parameter_group.address in instance.expressions.neptune_parameter_group_name.references

    not instance.expressions.engine_version.constant_value # defaults as latest version
    instance_parameter_group.expressions.family.constant_value == "neptune1.2"
}