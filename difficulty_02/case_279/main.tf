resource "aws_s3_bucket" "example" {
  bucket = "mybucket"

  object_lock_enabled = true
}

resource "aws_s3_bucket_object_lock_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 5
    }
  }
}