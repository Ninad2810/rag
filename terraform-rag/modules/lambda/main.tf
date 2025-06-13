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
  function_name    = "lambda_embed"
  filename         = data.archive_file.lambda_embed_zip.output_path
  source_code_hash = data.archive_file.lambda_embed_zip.output_base64sha256
  handler          = "lambda_embed.lambda_handler"
  runtime          = "python3.9"
  timeout          = 300
  memory_size      = 1024
  role             = var.lambda_embed_role_arn

  environment {
    variables = {
      OPENSEARCH_ENDPOINT = var.opensearch_endpoint
      AWS_REGION          = var.region
    }
  }

  tags = {
    Name        = "lambda_embed"
    Environment = var.environment
    Project     = "RAG System"
  }
}

resource "aws_lambda_function" "lambda_query" {
  function_name    = "lambda_query"
  filename         = data.archive_file.lambda_query_zip.output_path
  source_code_hash = data.archive_file.lambda_query_zip.output_base64sha256
  handler          = "lambda_query.lambda_handler"
  runtime          = "python3.9"
  timeout          = 300
  memory_size      = 1024
  role             = var.lambda_query_role_arn

  environment {
    variables = {
      OPENSEARCH_ENDPOINT = var.opensearch_endpoint
      AWS_REGION          = var.region
    }
  }

  tags = {
    Name        = "lambda_query"
    Environment = var.environment
    Project     = "RAG System"
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_embed.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.s3_bucket_arn
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_query.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}
