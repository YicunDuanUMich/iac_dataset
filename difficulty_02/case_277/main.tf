resource "aws_s3_bucket" "example" {
  bucket = "mybucket"
}
resource "aws_s3_bucket_object" "object" {
  bucket = "your_bucket_name"
  key    = "new_object_key"
  source = "path/to/file"
}