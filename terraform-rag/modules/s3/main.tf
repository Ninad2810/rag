# S3 bucket is now created in the root module
# This module only handles bucket configuration

# Create S3 bucket first without Lambda dependencies
resource "aws_s3_bucket" "document_bucket" {
  bucket = "${var.s3_conf.bucket_prefix}-${var.environment}"
  
  tags = merge(var.common_tags, {
    Name        = "${var.s3_conf.bucket_prefix}-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  })
}

resource "aws_s3_bucket_ownership_controls" "document_bucket_ownership" {
  bucket = var.bucket_name
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "document_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.document_bucket_ownership]
  bucket = var.bucket_name
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "document_bucket_versioning" {
  bucket = var.bucket_name
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_cors_configuration" "document_bucket_cors" {
  bucket = var.bucket_name

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "document_bucket_lifecycle" {
  bucket = var.bucket_name

  rule {
    id     = "archive-old-documents"
    status = "Enabled"
    
    filter {
      prefix = "docs/"
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "document_bucket_encryption" {
  bucket = var.bucket_name

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
