resource "aws_efs_file_system" "foo_with_lifecyle_policy" {
  creation_token = "my-product"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}