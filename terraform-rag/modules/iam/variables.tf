variable "environment" {
  description = "Deployment environment (dev, prod, etc.)"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for document storage"
  type        = string
}
