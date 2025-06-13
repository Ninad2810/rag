output "lambda_embed_arn" {
  description = "ARN of the Lambda embed function"
  value       = aws_lambda_function.lambda_embed.arn
}

output "lambda_embed_name" {
  description = "Name of the Lambda embed function"
  value       = aws_lambda_function.lambda_embed.function_name
}

output "lambda_query_arn" {
  description = "ARN of the Lambda query function"
  value       = aws_lambda_function.lambda_query.arn
}

output "lambda_query_name" {
  description = "Name of the Lambda query function"
  value       = aws_lambda_function.lambda_query.function_name
}

output "lambda_permission_s3" {
  description = "Lambda permission for S3 to invoke the function"
  value       = aws_lambda_permission.allow_s3
}
