# Use the REST API ID passed from the root module
# instead of creating a new REST API

resource "aws_api_gateway_resource" "query_resource" {
  rest_api_id = var.rest_api_id
  parent_id   = local.root_resource_id
  path_part   = var.api_path
}

# Get the root resource ID using a local value
locals {
  # This is a workaround since we can't directly get the root resource ID
  # We're using a known pattern for API Gateway root resource IDs
  root_resource_id = "${var.rest_api_id}/resources/${var.rest_api_id}"
}

resource "aws_api_gateway_method" "query_method" {
  rest_api_id   = var.rest_api_id
  resource_id   = aws_api_gateway_resource.query_resource.id
  http_method   = "POST"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "query_integration" {
  rest_api_id             = var.rest_api_id
  resource_id             = aws_api_gateway_resource.query_resource.id
  http_method             = aws_api_gateway_method.query_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_query_invoke_arn
}

resource "aws_api_gateway_method_response" "query_response_200" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.query_resource.id
  http_method = aws_api_gateway_method.query_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# API Gateway module (create before Lambda to get the execution ARN)
resource "aws_api_gateway_rest_api" "rag_api" {
  name        = "${var.api_name_prefix}-${var.environment}"
  description = "API Gateway for ${var.project_name}"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  
  tags = merge(var.common_tags, {
    Name        = "${var.api_name_prefix}-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  })
}

# CORS configuration
resource "aws_api_gateway_method" "query_options" {
  rest_api_id   = var.rest_api_id
  resource_id   = aws_api_gateway_resource.query_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "query_options_integration" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.query_resource.id
  http_method = aws_api_gateway_method.query_options.http_method
  type        = "MOCK"
  
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "query_options_response_200" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.query_resource.id
  http_method = aws_api_gateway_method.query_options.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "query_options_integration_response" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.query_resource.id
  http_method = aws_api_gateway_method.query_options.http_method
  status_code = aws_api_gateway_method_response.query_options_response_200.status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_deployment" "rag_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.query_integration,
    aws_api_gateway_integration.query_options_integration
  ]

  rest_api_id = var.rest_api_id
  stage_name  = var.stage_name

  lifecycle {
    create_before_destroy = true
  }

  variables = {
    # Force redeployment when something changes
    deployed_at = timestamp()
  }
}

# API Gateway Usage Plan and API Key
resource "aws_api_gateway_usage_plan" "rag_usage_plan" {
  name        = "rag-usage-plan-${var.environment}"
  description = "Usage plan for ${var.project_name} API"

  api_stages {
    api_id = var.rest_api_id
    stage  = aws_api_gateway_deployment.rag_api_deployment.stage_name
  }

  quota_settings {
    limit  = 1000
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 20
    rate_limit  = 10
  }

  tags = merge(var.common_tags, {
    Name        = "rag-usage-plan-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  })
}

resource "aws_api_gateway_api_key" "rag_api_key" {
  name = "rag-api-key-${var.environment}"
  description = "API key for ${var.project_name}"
  enabled = true

  tags = merge(var.common_tags, {
    Name        = "rag-api-key-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  })
}

resource "aws_api_gateway_usage_plan_key" "rag_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.rag_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.rag_usage_plan.id
}
