package terraform.validation

default has_aws_iam_role = false 
default has_aws_iam_role_policy_attachment = false 
default has_aws_eks_cluster = false 

has_aws_iam_role {
    some i
    role := input.planned_values.root_module.resources[i]
    role.type == "aws_iam_role"
    role.values.name != null
    role.values.assume_role_policy != null
}

has_aws_iam_role_policy_attachment {
    some i
    attachment := input.planned_values.root_module.resources[i]
    attachment.type == "aws_iam_role_policy_attachment"
    attachment.values.policy_arn == "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    attachment.values.role != null
}

has_aws_eks_cluster {
    some i
    eks_cluster := input.configuration.root_module.resources[i]
    eks_cluster.type == "aws_eks_cluster"
    eks_cluster.expressions.name != null
    eks_cluster.expressions.role_arn != null
    eks_cluster.expressions.vpc_config[_].subnet_ids != null
    count(eks_cluster.expressions.vpc_config[_].subnet_ids) > 0
    count(eks_cluster.depends_on) == 1
}

valid_configuration {
    has_aws_iam_role
    has_aws_iam_role_policy_attachment
    has_aws_eks_cluster
}