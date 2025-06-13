variable "bucket_name" {
  description = "Name of the S3 bucket for document storage"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, prod, etc.)"
  type        = string
}

variable "lambda_embed_arn" {
  description = "ARN of the Lambda function for embedding documents"
  type        = string
}

variable "lambda_permission_s3" {
  description = "Lambda permission for S3 to invoke the function"
  type        = any
}
