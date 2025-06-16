variable "bucket_name" {
  description = "Name of the S3 bucket for document storage"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, prod, etc.)"
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

variable "bucket_prefix" {
  description = "Prefix for the S3 bucket name"
  type        = string
  default     = "rag-document-store"
}