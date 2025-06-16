output "invoke_url" {
  description = "Invoke URL of the API Gateway"
  value       = "${aws_api_gateway_deployment.rag_api_deployment.invoke_url}${aws_api_gateway_resource.query_resource.path}"
}

output "api_key" {
  description = "API key for the API Gateway"
  value       = aws_api_gateway_api_key.rag_api_key.value
  sensitive   = true
}
