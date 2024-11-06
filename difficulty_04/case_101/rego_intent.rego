package terraform.analysis

default has_aws_iam_role = false
default has_aws_iam_role_policy_attachment = false
default has_aws_eks_cluster = false

find_resource(rtype, rname) = resource {
    resource = input.configuration.root_module.resources[_]
    resource.type == rtype
    resource.name == rname
}

has_aws_iam_role {
    r := find_resource("aws_iam_role", "demo")
    r.expressions.name.constant_value == "eks-cluster-demo"
    r.expressions.assume_role_policy
}

has_aws_iam_role_policy_attachment {
    r := input.configuration.root_module.resources[_]
    r.type == "aws_iam_role_policy_attachment"
    r.expressions.policy_arn.constant_value == "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    r.expressions.role.references[_] == "aws_iam_role.demo.name"
}

has_aws_eks_cluster {
    r := find_resource("aws_eks_cluster", "demo")
    r.expressions.role_arn.references[_] == "aws_iam_role.demo.arn"
    count(r.expressions.vpc_config[_].subnet_ids.references) >= 4
    count(r.depends_on) == 1
}

valid_config {
    has_aws_iam_role
    has_aws_iam_role_policy_attachment
    has_aws_eks_cluster
}