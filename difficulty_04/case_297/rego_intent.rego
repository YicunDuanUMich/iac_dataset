package autograder

import rego.v1

codebuild_project_valid(codebuild_project, s3_bucket) if {
        some artifact in codebuild_project.expressions.artifacts
        s3_bucket.address in artifact.location.references
        artifact.type.constant_value == "S3"
        artifact.name.constant_value

        some environment in codebuild_project.expressions.environment
        environment.compute_type.constant_value == "BUILD_GENERAL1_SMALL"
        environment.image.constant_value == "alpine"
        environment.type.constant_value == "LINUX_CONTAINER"

        some source in codebuild_project.expressions.source
        source.git_clone_depth.constant_value == 1
        source.location.constant_value == "github.com/source-location"
        source.type.constant_value == "GITHUB"
}

default valid := false

valid if {
        resources := input.configuration.root_module.resources
        some codebuild_project in resources
        codebuild_project.type == "aws_codebuild_project"
        some s3_bucket in resources
        s3_bucket.type == "aws_s3_bucket"
        codebuild_project_valid(codebuild_project, s3_bucket)
}