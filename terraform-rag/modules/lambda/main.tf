data "archive_file" "lambda_embed_zip" {
  type        = "zip"
  source_file = var.lambda_embed_source_file
  output_path = "${path.module}/lambda_embed.zip"
}

data "archive_file" "lambda_query_zip" {
  type        = "zip"
  source_file = var.lambda_query_source_file
  output_path = "${path.module}/lambda_query.zip"
}

resource "aws_lambda_function" "lambda_embed" {
  function_name    = var.lambda_embed_name
  filename         = data.archive_file.lambda_embed_zip.output_path
  source_code_hash = data.archive_file.lambda_embed_zip.output_base64sha256
  handler          = "lambda_embed.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  role             = var.lambda_embed_role_arn

  environment {
    variables = {
      OPENSEARCH_ENDPOINT = var.opensearch_endpoint
      AWS_REGION          = var.region
      EMBEDDINGS_MODEL    = var.embeddings_model
    }
  }

  tags = merge(var.common_tags, {
    Name        = var.lambda_embed_name
    Environment = var.environment
    Project     = var.project_name
  })
}

resource "aws_lambda_function" "lambda_query" {
  function_name    = var.lambda_query_name
  filename         = data.archive_file.lambda_query_zip.output_path
  source_code_hash = data.archive_file.lambda_query_zip.output_base64sha256
  handler          = "lambda_query.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  role             = var.lambda_query_role_arn

  environment {
    variables = {
      OPENSEARCH_ENDPOINT = var.opensearch_endpoint
      AWS_REGION          = var.region
      EMBEDDINGS_MODEL    = var.embeddings_model
      QUERY_MODEL         = var.query_model
    }
  }

  tags = merge(var.common_tags, {
    Name        = var.lambda_query_name
    Environment = var.environment
    Project     = var.project_name
  })
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_embed.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.s3_bucket_arn
}

resource "aws_lambda_permission" "allow_api_gateway_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_query.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}
