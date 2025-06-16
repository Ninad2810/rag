variable "environment" {
  description = "Deployment environment (dev, prod, etc.)"
  type        = string
}

variable "lambda_query_invoke_arn" {
  description = "Invoke ARN of the Lambda query function"
  type        = string
}

variable "stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "prod"
}

variable "rest_api_id" {
  description = "ID of the REST API Gateway created in the root module"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
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

variable "api_path" {
  description = "Path part for the API Gateway resource"
  type        = string
  default     = "query"
}

variable "api_name_prefix" {
  description = "Prefix for the API Gateway name"
  type        = string
  default     = "rag-api"
}