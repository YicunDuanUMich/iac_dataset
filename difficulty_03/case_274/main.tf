resource "aws_s3_bucket" "test" {
  bucket = "my-tf-test-bucket"
}

resource "aws_s3_bucket" "inventory" {
  bucket = "my-tf-inventory-bucket"
}

resource "aws_s3_bucket_inventory" "test" {
  bucket = aws_s3_bucket.test.id
  name   = "EntireBucketWeekly"

  included_object_versions = "Current"

  schedule {
    frequency = "Weekly"
  }

  destination {
    bucket {
      format     = "CSV"
      bucket_arn = aws_s3_bucket.inventory.arn
    }
  }
}