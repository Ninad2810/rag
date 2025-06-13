output "domain_id" {
  description = "ID of the OpenSearch domain"
  value       = aws_opensearch_domain.vector_store.domain_id
}

output "domain_arn" {
  description = "ARN of the OpenSearch domain"
  value       = aws_opensearch_domain.vector_store.arn
}

output "domain_endpoint" {
  description = "Endpoint of the OpenSearch domain"
  value       = aws_opensearch_domain.vector_store.endpoint
}

output "dashboard_endpoint" {
  description = "Dashboard endpoint of the OpenSearch domain"
  value       = "${aws_opensearch_domain.vector_store.endpoint}/_dashboards/"
}
