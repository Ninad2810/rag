output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.document_bucket.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.document_bucket.arn
}

output "opensearch_endpoint" {
  description = "Endpoint of the OpenSearch domain"
  value       = module.opensearch.domain_endpoint
}

output "opensearch_dashboard_endpoint" {
  description = "Dashboard endpoint of the OpenSearch domain"
  value       = module.opensearch.dashboard_endpoint
}

output "api_invoke_url" {
  description = "Invoke URL of the API Gateway"
  value       = module.api_gateway.invoke_url
}

output "api_key" {
  description = "API key for the API Gateway"
  value       = module.api_gateway.api_key
  sensitive   = true
}

output "lambda_embed_name" {
  description = "Name of the Lambda embed function"
  value       = module.lambda.lambda_embed_name
}

output "lambda_query_name" {
  description = "Name of the Lambda query function"
  value       = module.lambda.lambda_query_name
}

output "embeddings_model" {
  description = "Model used for generating embeddings"
  value       = var.ml_model_conf.embeddings_model
}

output "query_model" {
  description = "Model used for query processing"
  value       = var.ml_model_conf.query_model
}
