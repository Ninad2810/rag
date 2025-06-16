variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "account_id" {
  description = "AWS account ID"
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

# S3 Configuration
variable "bucket_prefix" {
  description = "Prefix for the S3 bucket name"
  type        = string
  default     = "rag-document-store"
}

variable "s3_notification_prefix" {
  description = "Prefix for S3 notification filter"
  type        = string
  default     = "docs/"
}

variable "s3_notification_file_types" {
  description = "List of file types to trigger Lambda on S3 upload"
  type        = list(string)
  default     = [".pdf", ".txt", ".md", ".docx"]
}

# Lambda Configuration
variable "lambda_embed_source_file" {
  description = "Path to the Lambda embed source file"
  type        = string
  default     = "../lambda_embed.py"
}

variable "lambda_query_source_file" {
  description = "Path to the Lambda query source file"
  type        = string
  default     = "../lambda_query.py"
}

variable "lambda_embed_name_prefix" {
  description = "Prefix for the Lambda embed function name"
  type        = string
  default     = "rag-embed"
}

variable "lambda_query_name_prefix" {
  description = "Prefix for the Lambda query function name"
  type        = string
  default     = "rag-query"
}

variable "lambda_memory_size" {
  description = "Memory size for Lambda functions in MB"
  type        = number
  default     = 1024
}

variable "lambda_timeout" {
  description = "Timeout for Lambda functions in seconds"
  type        = number
  default     = 300
}

variable "lambda_runtime" {
  description = "Runtime for Lambda functions"
  type        = string
  default     = "python3.9"
}

variable "embeddings_model" {
  description = "Model to use for generating embeddings"
  type        = string
  default     = "sentence-transformers/all-MiniLM-L6-v2"
}

variable "query_model" {
  description = "Model to use for query processing"
  type        = string
  default     = "gpt-3.5-turbo"
}

# OpenSearch Configuration
variable "domain_name" {
  description = "Name of the OpenSearch domain"
  type        = string
}

variable "opensearch_domain_prefix" {
  description = "Prefix for the OpenSearch domain name"
  type        = string
  default     = "rag-vector-store"
}

variable "opensearch_instance_type" {
  description = "Instance type for OpenSearch"
  type        = string
  default     = "t3.small.search"
}

variable "opensearch_instance_count" {
  description = "Number of instances for OpenSearch"
  type        = number
  default     = 1
}

variable "opensearch_volume_size" {
  description = "Volume size for OpenSearch in GB"
  type        = number
  default     = 10
}

variable "opensearch_master_user" {
  description = "Master user name for OpenSearch"
  type        = string
  default     = "admin"
}

variable "opensearch_master_password" {
  description = "Master user password for OpenSearch"
  type        = string
  sensitive   = true
}

# API Gateway Configuration
variable "api_name_prefix" {
  description = "Prefix for the API Gateway name"
  type        = string
  default     = "rag-api"
}

variable "api_stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "dev"
}

variable "api_path" {
  description = "Path part for the API Gateway resource"
  type        = string
  default     = "query"
}
