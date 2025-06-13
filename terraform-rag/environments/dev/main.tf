provider "aws" {
  region = var.region
}

# API Gateway module (needs to be created first to get the execution ARN)
module "api_gateway" {
  source = "../../modules/api_gateway"

  environment           = var.environment
  lambda_query_invoke_arn = module.lambda.lambda_query_arn
  stage_name            = "dev"

  depends_on = [module.lambda]
}

# IAM module
module "iam" {
  source = "../../modules/iam"

  environment   = var.environment
  s3_bucket_arn = module.s3.bucket_arn
}

# Lambda module
module "lambda" {
  source = "../../modules/lambda"

  environment             = var.environment
  region                  = var.region
  lambda_embed_source_file = var.lambda_embed_source_file
  lambda_query_source_file = var.lambda_query_source_file
  lambda_embed_role_arn   = module.iam.lambda_embed_role_arn
  lambda_query_role_arn   = module.iam.lambda_query_role_arn
  opensearch_endpoint     = module.opensearch.domain_endpoint
  s3_bucket_arn           = module.s3.bucket_arn
  api_gateway_execution_arn = module.api_gateway.api_execution_arn

  depends_on = [module.iam, module.opensearch]
}

# OpenSearch module
module "opensearch" {
  source = "../../modules/opensearch"

  domain_name         = "rag-vector-store-${var.environment}"
  environment         = var.environment
  instance_type       = "t3.small.search"
  instance_count      = 1
  volume_size         = 10
  master_user_name    = var.opensearch_master_user
  master_user_password = var.opensearch_master_password
  allowed_role_arns   = [module.iam.lambda_embed_role_arn, module.iam.lambda_query_role_arn]
  region              = var.region
  account_id          = var.account_id

  depends_on = [module.iam]
}

# S3 module
module "s3" {
  source = "../../modules/s3"

  bucket_name        = "rag-document-store-${var.environment}"
  environment        = var.environment
  lambda_embed_arn   = module.lambda.lambda_embed_arn
  lambda_permission_s3 = module.lambda.lambda_permission_s3

  depends_on = [module.lambda]
}
