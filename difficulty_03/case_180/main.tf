resource "aws_sagemaker_code_repository" "example" {
  code_repository_name = "my-notebook-instance-code-repo"

  git_config {
    repository_url = "https://github.com/hashicorp/terraform-provider-aws.git"
  }
}

resource "aws_sagemaker_notebook_instance" "ni" {
  name                    = "my-notebook-instance"
  role_arn                = aws_iam_role.example.arn
  instance_type           = "ml.t2.medium"
  default_code_repository = aws_sagemaker_code_repository.example.code_repository_name
}

resource "aws_iam_role" "example" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

data "aws_sagemaker_prebuilt_ecr_image" "test" {
  repository_name = "kmeans"
}