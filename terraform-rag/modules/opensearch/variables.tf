variable "domain_name" {
  description = "Name of the OpenSearch domain"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, prod, etc.)"
  type        = string
}

variable "instance_type" {
  description = "Instance type for OpenSearch nodes"
  type        = string
  default     = "r6g.large.search"
}

variable "instance_count" {
  description = "Number of OpenSearch nodes"
  type        = number
  default     = 2
}

variable "volume_size" {
  description = "Size of the EBS volume in GB"
  type        = number
  default     = 100
}

variable "master_user_name" {
  description = "Master user name for OpenSearch"
  type        = string
  default     = "admin"
}

variable "master_user_password" {
  description = "Master user password for OpenSearch"
  type        = string
  sensitive   = true
}

variable "allowed_role_arns" {
  description = "List of IAM role ARNs allowed to access OpenSearch"
  type        = list(string)
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}
