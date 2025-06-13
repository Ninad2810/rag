resource "aws_s3_bucket" "document_bucket" {
  bucket = var.bucket_name
  force_destroy = true

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
    Project     = "RAG System"
  }
}

resource "aws_s3_bucket_ownership_controls" "document_bucket_ownership" {
  bucket = aws_s3_bucket.document_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "document_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.document_bucket_ownership]
  bucket = aws_s3_bucket.document_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "document_bucket_versioning" {
  bucket = aws_s3_bucket.document_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.document_bucket.id

  lambda_function {
    lambda_function_arn = var.lambda_embed_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "docs/"
    filter_suffix       = ".pdf"
  }

  lambda_function {
    lambda_function_arn = var.lambda_embed_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "docs/"
    filter_suffix       = ".txt"
  }

  depends_on = [var.lambda_permission_s3]
}

resource "aws_s3_bucket_cors_configuration" "document_bucket_cors" {
  bucket = aws_s3_bucket.document_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
