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
