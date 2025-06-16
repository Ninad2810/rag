# Lambda Embed Role
resource "aws_iam_role" "lambda_embed_role" {
  name = "lambda-embed-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "lambda-embed-role-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  })
}

# Lambda Query Role
resource "aws_iam_role" "lambda_query_role" {
  name = "lambda-query-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "lambda-query-role-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  })
}

# Lambda Basic Execution Policy
resource "aws_iam_policy" "lambda_basic_execution" {
  name        = "lambda-basic-execution-policy-${var.environment}"
  description = "Basic execution policy for Lambda functions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "lambda-basic-execution-policy-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  })
}

# S3 Access Policy
resource "aws_iam_policy" "s3_access" {
  name        = "s3-access-policy-${var.environment}"
  description = "Policy for accessing S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = [
          "${var.s3_bucket_arn}",
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "s3-access-policy-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  })
}

# Bedrock Access Policy
resource "aws_iam_policy" "bedrock_access" {
  name        = "bedrock-access-policy-${var.environment}"
  description = "Policy for accessing Bedrock models"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "bedrock:ListFoundationModels",
          "bedrock:GetFoundationModel"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "bedrock-access-policy-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  })
}

# Bedrock Runtime Access Policy
resource "aws_iam_policy" "bedrock_runtime_access" {
  name        = "bedrock-runtime-access-policy-${var.environment}"
  description = "Policy for invoking Bedrock runtime models"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "bedrock:InvokeModel",
          "bedrock-runtime:InvokeModel",
          "bedrock-runtime:InvokeModelWithResponseStream"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "bedrock-runtime-access-policy-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  })
}

# OpenSearch Access Policy
resource "aws_iam_policy" "opensearch_access" {
  name        = "opensearch-access-policy-${var.environment}"
  description = "Policy for accessing OpenSearch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "es:ESHttpGet",
          "es:ESHttpPut",
          "es:ESHttpPost",
          "es:ESHttpDelete"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "opensearch-access-policy-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  })
}

# Attach policies to Lambda Embed Role
resource "aws_iam_role_policy_attachment" "embed_basic_execution" {
  role       = aws_iam_role.lambda_embed_role.name
  policy_arn = aws_iam_policy.lambda_basic_execution.arn
}

resource "aws_iam_role_policy_attachment" "embed_s3_access" {
  role       = aws_iam_role.lambda_embed_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_role_policy_attachment" "embed_bedrock_access" {
  role       = aws_iam_role.lambda_embed_role.name
  policy_arn = aws_iam_policy.bedrock_access.arn
}

resource "aws_iam_role_policy_attachment" "embed_bedrock_runtime_access" {
  role       = aws_iam_role.lambda_embed_role.name
  policy_arn = aws_iam_policy.bedrock_runtime_access.arn
}

resource "aws_iam_role_policy_attachment" "embed_opensearch_access" {
  role       = aws_iam_role.lambda_embed_role.name
  policy_arn = aws_iam_policy.opensearch_access.arn
}

# Attach policies to Lambda Query Role
resource "aws_iam_role_policy_attachment" "query_basic_execution" {
  role       = aws_iam_role.lambda_query_role.name
  policy_arn = aws_iam_policy.lambda_basic_execution.arn
}

resource "aws_iam_role_policy_attachment" "query_bedrock_access" {
  role       = aws_iam_role.lambda_query_role.name
  policy_arn = aws_iam_policy.bedrock_access.arn
}

resource "aws_iam_role_policy_attachment" "query_bedrock_runtime_access" {
  role       = aws_iam_role.lambda_query_role.name
  policy_arn = aws_iam_policy.bedrock_runtime_access.arn
}

resource "aws_iam_role_policy_attachment" "query_opensearch_access" {
  role       = aws_iam_role.lambda_query_role.name
  policy_arn = aws_iam_policy.opensearch_access.arn
}
