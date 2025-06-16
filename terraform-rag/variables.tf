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
variable "s3_conf" {
  description = "S3 bucket configuration"
  type = object({
    bucket_prefix = string
    s3_notification_prefix = string
    s3_notification_file_types = list(string)
  })
  default = {
    bucket_prefix = "rag-document-store"
    s3_notification_prefix = "docs/"
    s3_notification_file_types = [".pdf", ".txt", ".md", ".docx"]
  }
}

# Lambda Configuration
variable "lambda_conf" {
  description = "Lambda function configuration"
  type = object({
    lambda_embed_source_file = string
    lambda_query_source_file = string
    lambda_embed_name_prefix = string
    lambda_query_name_prefix = string
    lambda_memory_size = number
    lambda_timeout = number
    lambda_runtime = string
  })
  default = {
    lambda_embed_source_file = "../lambda_embed.py"
    lambda_query_source_file = "../lambda_query.py"
    lambda_embed_name_prefix = "rag-embed"
    lambda_query_name_prefix = "rag-query"
    lambda_memory_size = 1024
    lambda_timeout = 300
    lambda_runtime = "python3.9"
  }
}

# Model Configuration
variable "ml_model_conf" {
  description = "Machine learning model configuration"
  type = object({
    embeddings_model = string
    query_model = string
  })
  default = {
    embeddings_model = "sentence-transformers/all-MiniLM-L6-v2"
    query_model = "gpt-3.5-turbo"
  }
}

# OpenSearch Configuration
variable "opensearch_conf" {
  description = "OpenSearch configuration"
  type = object({
    opensearch_domain_prefix = string
    opensearch_instance_type = string
    opensearch_instance_count = number
    opensearch_volume_size = number
    opensearch_master_user = string
    opensearch_master_password = string
  })
  default = {
    opensearch_domain_prefix = "rag-vector-store"
    opensearch_instance_type = "t3.small.search"
    opensearch_instance_count = 1
    opensearch_volume_size = 10
    opensearch_master_user = "admin"
    opensearch_master_password = "changeme"
  }
}

# API Gateway Configuration
variable "api_conf" {
  description = "API Gateway configuration"
  type = object({
    api_name_prefix = string
    api_stage_name = string
    api_path = string
  })
  default = {
    api_name_prefix = "rag-api"
    api_stage_name = "dev"
    api_path = "query"
  }
}
