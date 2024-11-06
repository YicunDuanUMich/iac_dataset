resource "aws_iam_group" "group" {
  name = "my-group"
  path = "/users/"
}