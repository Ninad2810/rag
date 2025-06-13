output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3.bucket_id
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
