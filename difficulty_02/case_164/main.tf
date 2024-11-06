resource "aws_dynamodb_table" "example" {
  name     = "orders"
  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_kinesis_stream" "example" {
  name        = "order_item_changes"
  shard_count = 1
}

resource "aws_dynamodb_kinesis_streaming_destination" "example" {
  stream_arn = aws_kinesis_stream.example.arn
  table_name = aws_dynamodb_table.example.name
}