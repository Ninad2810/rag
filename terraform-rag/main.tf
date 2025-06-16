provider "aws" {
  region = var.region
}

# # Create S3 bucket first without Lambda dependencies
# resource "aws_s3_bucket" "document_bucket" {
#   bucket = "${var.bucket_prefix}-${var.environment}"
  
#   tags = merge(var.common_tags, {
#     Name        = "${var.bucket_prefix}-${var.environment}"
#     Environment = var.environment
#     Project     = var.project_name
#   })
# }

# IAM module
module "iam" {
  source = "./modules/iam"

  environment   = var.environment
  s3_bucket_arn = module.s3.document_bucket.arn
  # project_name  = var.project_name
  # common_tags   = var.common_tags
}

# OpenSearch module
module "opensearch" {
  source = "./modules/opensearch"

  domain_name         = "${var.opensearch_domain_prefix}-${var.environment}"
  environment         = var.environment
  instance_type       = var.opensearch_instance_type
  instance_count      = var.opensearch_instance_count
  volume_size         = var.opensearch_volume_size
  master_user_name    = var.opensearch_master_user
  master_user_password = var.opensearch_master_password
  allowed_role_arns   = [module.iam.lambda_embed_role_arn, module.iam.lambda_query_role_arn]
  region              = var.region
  account_id          = var.account_id
  # project_name        = var.project_name
  # common_tags         = var.common_tags

  depends_on = [module.iam]
}

# # API Gateway module (create before Lambda to get the execution ARN)
# resource "aws_api_gateway_rest_api" "rag_api" {
#   name        = "${var.api_name_prefix}-${var.environment}"
#   description = "API Gateway for ${var.project_name}"
  
#   endpoint_configuration {
#     types = ["REGIONAL"]
#   }
  
#   tags = merge(var.common_tags, {
#     Name        = "${var.api_name_prefix}-${var.environment}"
#     Environment = var.environment
#     Project     = var.project_name
#   })
# }

# Lambda module
module "lambda" {
  source = "./modules/lambda"

  environment             = var.environment
  region                  = var.region
  lambda_embed_source_file = var.lambda_embed_source_file
  lambda_query_source_file = var.lambda_query_source_file
  lambda_embed_role_arn   = module.iam.lambda_embed_role_arn
  lambda_query_role_arn   = module.iam.lambda_query_role_arn
  opensearch_endpoint     = module.opensearch.domain_endpoint
  s3_bucket_arn           = module.s3.document_bucket.arn
  api_gateway_execution_arn = module.api_gateway.rag_api.execution_arn
  embeddings_model        = var.embeddings_model
  query_model             = var.query_model
  # lambda_embed_name       = "${var.lambda_embed_name_prefix}-${var.environment}"
  # lambda_query_name       = "${var.lambda_query_name_prefix}-${var.environment}"
  # lambda_memory_size      = var.lambda_memory_size
  # lambda_timeout          = var.lambda_timeout
  # lambda_runtime          = var.lambda_runtime
  # project_name            = var.project_name
  # common_tags             = var.common_tags

  depends_on = [module.iam, module.opensearch, module.s3.document_bucket, module.api_gateway.rag_api]
}

# Configure S3 bucket notifications after Lambda is created
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.document_bucket.id

  dynamic "lambda_function" {
    for_each = var.s3_notification_file_types
    content {
      lambda_function_arn = module.lambda.lambda_embed_arn
      events              = ["s3:ObjectCreated:*"]
      filter_prefix       = var.s3_notification_prefix
      filter_suffix       = lambda_function.value
    }
  }

  depends_on = [module.lambda]
}

# S3 module for additional bucket configuration
module "s3" {
  source = "./modules/s3"

  bucket_name        = module.s3.document_bucket.id
  environment        = var.environment
  # project_name       = var.project_name
  # common_tags        = var.common_tags

  depends_on = [aws_s3_bucket.document_bucket]
}

# Complete API Gateway configuration after Lambda is created
module "api_gateway" {
  source = "./modules/api_gateway"

  environment           = var.environment
  lambda_query_invoke_arn = module.lambda.lambda_query_arn
  stage_name            = var.api_stage_name
  rest_api_id           = module.api_gateway.rag_api.id
  # project_name          = var.project_name
  # common_tags           = var.common_tags
  # api_path              = var.api_path
  
  depends_on = [module.lambda]
}
