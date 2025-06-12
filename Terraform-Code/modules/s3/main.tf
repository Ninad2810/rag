resource "aws_s3_bucket" "docs" {
  bucket = var.bucket_name
  force_destroy = true
}