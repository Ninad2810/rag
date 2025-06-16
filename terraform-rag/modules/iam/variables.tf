variable "environment" {
  description = "Deployment environment (dev, prod, etc.)"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for document storage"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "RAG System"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
