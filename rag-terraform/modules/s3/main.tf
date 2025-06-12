resource "aws_s3_bucket" "document_store" {
 bucket = var.bucket_name

 tags = {
   Name        = var.bucket_name
   Environment = var.environment
 }
}

resource "aws_s3_bucket_ownership_controls" "document_store" {
 bucket = aws_s3_bucket.document_store.id
 rule {
   object_ownership = "BucketOwnerPreferred"
 }
}

resource "aws_s3_bucket_acl" "document_store" {
 depends_on = [aws_s3_bucket_ownership_controls.document_store]
 bucket = aws_s3_bucket.document_store.id
 acl    = "private"
}

resource "aws_s3_bucket_versioning" "document_store" {
 bucket = aws_s3_bucket.document_store.id
 versioning_configuration {
   status = "Enabled"
 }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "document_store" {
 bucket = aws_s3_bucket.document_store.id

 rule {
   apply_server_side_encryption_by_default {
     sse_algorithm = "AES256"
   }
 }
}