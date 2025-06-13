variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
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

variable "lambda_embed_source_file" {
  description = "Path to the Lambda embed source file"
  type        = string
  default     = "../../../lambda_embed.py"
}

variable "lambda_query_source_file" {
  description = "Path to the Lambda query source file"
  type        = string
  default     = "../../../lambda_query.py"
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
