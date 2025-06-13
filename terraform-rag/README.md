# Terraform RAG System Infrastructure

This directory contains Terraform code to deploy the complete RAG (Retrieval-Augmented Generation) system infrastructure on AWS.

## Architecture

The RAG system consists of the following components:

- **S3 Bucket**: Stores the original documents
- **Lambda Functions**:
  - `lambda_embed`: Processes documents and generates embeddings
  - `lambda_query`: Handles queries and generates responses
- **OpenSearch Domain**: Stores document embeddings for vector search
- **API Gateway**: Provides an HTTP endpoint for querying the system
- **IAM Roles and Policies**: Manages permissions for all components

## Directory Structure

```
terraform-rag/
├── modules/                  # Reusable Terraform modules
│   ├── api_gateway/          # API Gateway configuration
│   ├── iam/                  # IAM roles and policies
│   ├── lambda/               # Lambda functions
│   ├── opensearch/           # OpenSearch domain
│   └── s3/                   # S3 bucket
├── environments/             # Environment-specific configurations
│   ├── dev/                  # Development environment
│   └── prod/                 # Production environment
└── README.md                 # This file
```

## Prerequisites

- Terraform v1.0.0 or later
- AWS CLI configured with appropriate credentials
- Python 3.9 or later
- Lambda function code (`lambda_embed.py` and `lambda_query.py`)

## Deployment Instructions

### 1. Prepare the Environment

Choose the environment you want to deploy (dev or prod):

```bash
cd environments/dev  # or environments/prod
```

Create a `terraform.tfvars` file based on the example:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit the `terraform.tfvars` file to set your AWS account ID and other variables:

```
environment = "dev"
region = "ap-south-1"
account_id = "YOUR_AWS_ACCOUNT_ID"
lambda_embed_source_file = "../../../lambda_embed.py"
lambda_query_source_file = "../../../lambda_query.py"
opensearch_master_user = "admin"
opensearch_master_password = "YourSecurePassword"
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan the Deployment

```bash
terraform plan
```

Review the plan to ensure it will create the expected resources.

### 4. Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment.

### 5. Access the Outputs

After deployment completes, Terraform will display the outputs:

- `s3_bucket_name`: Name of the S3 bucket for document storage
- `opensearch_endpoint`: Endpoint of the OpenSearch domain
- `opensearch_dashboard_endpoint`: Dashboard endpoint of the OpenSearch domain
- `api_invoke_url`: Invoke URL of the API Gateway
- `api_key`: API key for the API Gateway (sensitive)

You can retrieve these outputs later with:

```bash
terraform output
```

To view sensitive outputs:

```bash
terraform output api_key
```

## Customization

### Modifying Lambda Functions

If you need to update the Lambda function code:

1. Edit the Lambda function files (`lambda_embed.py` and `lambda_query.py`)
2. Run `terraform apply` to deploy the changes

### Scaling OpenSearch

To scale the OpenSearch domain:

1. Edit the `instance_type`, `instance_count`, or `volume_size` variables in the environment's `main.tf` file
2. Run `terraform apply` to apply the changes

### Adding API Gateway Resources

To add new API Gateway resources:

1. Edit the `api_gateway/main.tf` file to add new resources, methods, and integrations
2. Run `terraform apply` to deploy the changes

## Cleanup

To destroy all resources created by Terraform:

```bash
terraform destroy
```

Type `yes` when prompted to confirm the destruction of resources.

## Security Considerations

- The OpenSearch domain is configured with encryption at rest and node-to-node encryption
- IAM roles follow the principle of least privilege
- API Gateway can be configured with API keys for authentication
- Sensitive values like passwords should be stored in AWS Secrets Manager in a production environment
