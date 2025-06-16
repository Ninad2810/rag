variable "environment" {
  description = "Deployment environment (dev, prod, etc.)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "lambda_embed_source_file" {
  description = "Path to the Lambda embed source file"
  type        = string
}

variable "lambda_query_source_file" {
  description = "Path to the Lambda query source file"
  type        = string
}

variable "lambda_embed_role_arn" {
  description = "ARN of the Lambda embed role"
  type        = string
}

variable "lambda_query_role_arn" {
  description = "ARN of the Lambda query role"
  type        = string
}

variable "opensearch_endpoint" {
  description = "Endpoint of the OpenSearch domain"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for document storage"
  type        = string
}

variable "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway"
  type        = string
}

variable "embeddings_model" {
  description = "Model to use for generating embeddings"
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}

variable "query_model" {
  description = "Model to use for query processing"
  type        = string
  default     = "anthropic.claude-3-haiku-20240307-v1:0"
}

variable "lambda_embed_name" {
  description = "Name of the Lambda embed function"
  type        = string
  default     = "rag-embed"
}

variable "lambda_query_name" {
  description = "Name of the Lambda query function"
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
