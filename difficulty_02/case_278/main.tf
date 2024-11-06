resource "aws_s3_bucket" "example" {
  bucket = "test-bucket"
}

resource "aws_s3_object" "object" {
  bucket = "my-bucket"
  key    = "new_object_key"
  source = "assets/test.pdf"
}