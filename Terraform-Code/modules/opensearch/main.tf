resource "aws_opensearch_domain" "rag" {
  domain_name           = var.domain_name
  engine_version        = "OpenSearch_2.11"
  cluster_config {
    instance_type = "t3.small.search"
    instance_count = 1
  }
  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }
  access_policies = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { "AWS": "*" },
        Action = "es:*",
        Resource = "*"
      }
    ]
  })
}

output "opensearch_arn" {
  value = aws_opensearch_domain.rag.arn
}

output "endpoint" {
  value = aws_opensearch_domain.rag.endpoint
}