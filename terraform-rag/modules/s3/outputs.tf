output "bucket_id" {
  description = "ID of the S3 bucket"
  value       = var.bucket_name
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = "arn:aws:s3:::${var.bucket_name}"
}
