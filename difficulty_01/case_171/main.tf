resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "example"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "UserId"

  attribute {
    name = "UserId"
    type = "S"
  }
}