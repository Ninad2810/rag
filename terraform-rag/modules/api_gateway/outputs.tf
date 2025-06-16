output "invoke_url" {
  description = "Invoke URL of the API Gateway"
  value       = "${var.rest_api_id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.rag_api_stage.stage_name}${aws_api_gateway_resource.query_resource.path}"
}

output "api_key" {
  description = "API key for the API Gateway"
  value       = aws_api_gateway_api_key.rag_api_key.value
  sensitive   = true
}

output "stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.rag_api_stage.stage_name
}
