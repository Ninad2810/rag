environment = "dev"
region = "ap-south-1"
account_id = "630522778239"
project_name = "RAG System"

# Common tags
common_tags = {
  ManagedBy = "Terraform"
  Owner     = "Data Science Team"
  Project   = "RAG System"
}

# S3 Configuration
s3_conf = {
  bucket_name = "rag-documents-bucket"
  bucket_prefix = "rag-document-store"
  s3_notification_prefix = "docs/"
  s3_notification_file_types = [".pdf", ".txt", ".md", ".docx"]
}

# Lambda Configuration
lambda_conf = {
  lambda_embed_source_file = "../lambda_embed.py"
  lambda_query_source_file = "../lambda_query.py"
  lambda_embed_name_prefix = "rag-embed"
  lambda_query_name_prefix = "rag-query"
  lambda_memory_size = 2048  # Increased for better performance
  lambda_timeout = 300
  lambda_runtime = "python3.9"
}

# Model configurations
ml_model_conf = {
  embeddings_model = "amazon.titan-embed-text-v2:0"
  query_model = "anthropic.claude-3-haiku-20240307-v1:0"
}

# OpenSearch Configuration
opensearch_conf = {
  domain_name = "test"
  opensearch_domain_prefix = "rag-vector-store"
  opensearch_instance_type = "t3.medium.search"
  opensearch_instance_count = 1
  opensearch_volume_size = 20
  opensearch_master_user = "admin"
  opensearch_master_password = "N!n@d2810"
}

# API Gateway Configuration
api_conf = {
  api_name_prefix = "rag-api"
  api_stage_name = "dev"
  api_path = "query"
}
