package terraform.validation

default has_aws_iam_policy_document_assume_role_eks = false
default has_aws_iam_role_demo_eks = false
default has_aws_iam_role_policy_attachment_demo_eks_AmazonEKSClusterPolicy = false
default has_aws_iam_role_policy_attachment_demo_eks_AmazonEKSVPCResourceController = false
default has_aws_eks_cluster_demo_eks = false

has_aws_iam_policy_document_assume_role_eks {
    assume_role_eks := input.configuration.root_module.resources[_]
    assume_role_eks.type == "aws_iam_policy_document"
    assume_role_eks.expressions.statement[_].effect.constant_value == "Allow"
    assume_role_eks.expressions.statement[_].principals[_].type.constant_value == "Service"
    assume_role_eks.expressions.statement[_].principals[_].identifiers.constant_value[_] == "eks.amazonaws.com"
    assume_role_eks.expressions.statement[_].actions.constant_value[_] == "sts:AssumeRole"
}

has_aws_iam_role_demo_eks {
    role := input.configuration.root_module.resources[_]
    role.type == "aws_iam_role"
    role.name == "demo_eks"
    role.expressions.assume_role_policy != null
}

has_aws_iam_role_policy_attachment_demo_eks_AmazonEKSClusterPolicy {
    policy_attachment := input.planned_values.root_module.resources[_]
    policy_attachment.type == "aws_iam_role_policy_attachment"
    policy_attachment.name == "demo_eks_AmazonEKSClusterPolicy"
    policy_attachment.values.policy_arn == "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    policy_attachment.values.role != null
}

has_aws_iam_role_policy_attachment_demo_eks_AmazonEKSVPCResourceController {
    policy_attachment := input.planned_values.root_module.resources[_]
    policy_attachment.type == "aws_iam_role_policy_attachment"
    policy_attachment.name == "demo_eks_AmazonEKSVPCResourceController"
    policy_attachment.values.policy_arn == "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
    policy_attachment.values.role != null
}

has_aws_eks_cluster_demo_eks {
    eks_cluster := input.configuration.root_module.resources[_]
    eks_cluster.type == "aws_eks_cluster"
    eks_cluster.name == "demo_eks"
    eks_cluster.expressions.role_arn != null
    eks_cluster.expressions.vpc_config[_].subnet_ids != null

    count(eks_cluster.depends_on) == 2
    # Checking for AmazonEKSClusterPolicy:
    worker_policy := input.configuration.root_module.resources[_]
    contains(eks_cluster.depends_on[_], worker_policy.name)
    contains(worker_policy.expressions.policy_arn.constant_value, "AmazonEKSClusterPolicy")

    # Checking for AmazonEKSVPCResourceController:
    worker_policy2 := input.configuration.root_module.resources[_]
    contains(eks_cluster.depends_on[_], worker_policy2.name)
    contains(worker_policy2.expressions.policy_arn.constant_value, "AmazonEKSVPCResourceController")
}

valid_configuration {
    has_aws_iam_policy_document_assume_role_eks
    has_aws_iam_role_demo_eks
    has_aws_iam_role_policy_attachment_demo_eks_AmazonEKSClusterPolicy
    has_aws_iam_role_policy_attachment_demo_eks_AmazonEKSVPCResourceController
    has_aws_eks_cluster_demo_eks
}