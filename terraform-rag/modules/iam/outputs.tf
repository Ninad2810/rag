output "lambda_embed_role_arn" {
  description = "ARN of the Lambda embed role"
  value       = aws_iam_role.lambda_embed_role.arn
}

output "lambda_embed_role_name" {
  description = "Name of the Lambda embed role"
  value       = aws_iam_role.lambda_embed_role.name
}

output "lambda_query_role_arn" {
  description = "ARN of the Lambda query role"
  value       = aws_iam_role.lambda_query_role.arn
}

output "lambda_query_role_name" {
  description = "Name of the Lambda query role"
  value       = aws_iam_role.lambda_query_role.name
}
