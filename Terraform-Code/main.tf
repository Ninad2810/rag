# Modularized Terraform Code for RAG Architecture on AWS

# Root main.tf (Composition Layer)
module "s3" {
  source = "./modules/s3"
  bucket_name = "rag-docs-bucket"
}

module "opensearch" {
  source = "./modules/opensearch"
  domain_name = "rag-opensearch"
}

module "iam" {
  source = "./modules/iam"
  s3_bucket_arn = module.s3.bucket_arn
  opensearch_arn = module.opensearch.opensearch_arn
}

module "lambda_embed" {
  source = "./modules/lambda_embed"
  role_arn = module.iam.lambda_embed_role_arn
  bucket_name = module.s3.bucket_name
  opensearch_endpoint = module.opensearch.endpoint
}

module "lambda_query" {
  source = "./modules/lambda_query"
  role_arn = module.iam.lambda_query_role_arn
  opensearch_endpoint = module.opensearch.endpoint
}

module "apigateway" {
  source = "./modules/apigateway"
  lambda_query_invoke_arn = module.lambda_query.lambda_invoke_arn
}

# modules/opensearch/main.tf


# modules/iam/main.tf
resource "aws_iam_role" "lambda_embed" {
  name = "lambda_embed_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy_attachment" "embed_policy" {
  name       = "embed-attach"
  roles      = [aws_iam_role.lambda_embed.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# (Add more detailed policies for Bedrock and OpenSearch)

output "lambda_embed_role_arn" {
  value = aws_iam_role.lambda_embed.arn
}

output "lambda_query_role_arn" {
  value = aws_iam_role.lambda_embed.arn # placeholder, duplicate role or separate
}

# modules/lambda_embed/main.tf
resource "aws_lambda_function" "embed" {
  function_name = "lambda_embed"
  role          = var.role_arn
  handler       = "main.handler"
  runtime       = "python3.11"
  filename      = "lambda_embed.zip"
  environment {
    variables = {
      BUCKET_NAME        = var.bucket_name
      OPENSEARCH_ENDPOINT = var.opensearch_endpoint
    }
  }
}

output "lambda_invoke_arn" {
  value = aws_lambda_function.embed.invoke_arn
}

# modules/lambda_query/main.tf (same pattern as embed)

# modules/apigateway/main.tf
resource "aws_apigatewayv2_api" "http_api" {
  name          = "rag-query-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.lambda_query_invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "query_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /query"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

output "query_api_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}
