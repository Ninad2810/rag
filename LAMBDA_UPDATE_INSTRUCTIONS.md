# Instructions for Updating Lambda Functions and Models

This document provides step-by-step instructions on how to make changes to the Lambda functions and models used in the RAG system.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Updating Lambda Functions](#updating-lambda-functions)
   - [Option 1: Using the AWS Console](#option-1-using-the-aws-console)
   - [Option 2: Using the AWS CLI](#option-2-using-the-aws-cli)
   - [Option 3: Using a Deployment Script](#option-3-using-a-deployment-script)
3. [Changing Bedrock Models](#changing-bedrock-models)
4. [Modifying OpenSearch Configuration](#modifying-opensearch-configuration)
5. [Troubleshooting](#troubleshooting)

## Prerequisites

Before making any changes, ensure you have:

- AWS CLI installed and configured with appropriate credentials
- Python 3.9 or later
- Required Python packages: `boto3`, `opensearch-py`, `requests-aws4auth`
- Access to the AWS account where the Lambda functions are deployed

## Updating Lambda Functions

### Option 1: Using the AWS Console

1. **Edit the Lambda function code locally**:
   - Make your changes to `lambda_embed.py` or `lambda_query.py`
   - Test your changes locally if possible

2. **Upload to AWS Lambda Console**:
   - Log in to the AWS Management Console
   - Navigate to Lambda service
   - Select the function you want to update (`lambda_embed` or `lambda_query`)
   - In the "Code" tab, click "Upload from" and select ".zip file"
   - Create a zip file containing your updated code and all dependencies
   - Upload the zip file

3. **Test the function**:
   - Use the "Test" tab in the Lambda console to create a test event
   - Run the test to verify your changes work as expected

### Option 2: Using the AWS CLI

1. **Edit the Lambda function code locally**:
   - Make your changes to `lambda_embed.py` or `lambda_query.py`

2. **Create a deployment package**:
   ```bash
   # Create a directory for your package
   mkdir -p lambda_package
   
   # Copy your updated code
   cp lambda_embed.py lambda_package/
   
   # Install dependencies in the package directory
   pip install -t lambda_package/ boto3 opensearch-py requests-aws4auth PyPDF2
   
   # Create a zip file
   cd lambda_package
   zip -r ../lambda_function.zip .
   cd ..
   ```

3. **Update the Lambda function**:
   ```bash
   # For lambda_embed
   aws lambda update-function-code \
     --function-name lambda_embed \
     --zip-file fileb://lambda_function.zip \
     --region ap-south-1
   
   # For lambda_query
   aws lambda update-function-code \
     --function-name lambda_query \
     --zip-file fileb://lambda_function.zip \
     --region ap-south-1
   ```

### Option 3: Using a Deployment Script

For more complex updates, you can use a Python script to modify and deploy the Lambda functions:

1. **Create an update script** (example for `lambda_embed`):
   ```python
   #!/usr/bin/env python3
   import boto3
   import json
   import os
   import zipfile
   import tempfile
   import shutil

   # Create a Lambda client
   lambda_client = boto3.client('lambda', region_name='ap-south-1')

   # Create a temporary directory
   temp_dir = tempfile.mkdtemp()
   try:
       # Download the current Lambda function code
       response = lambda_client.get_function(FunctionName='lambda_embed')
       code_url = response['Code']['Location']
       
       # Download the zip file
       import urllib.request
       zip_path = os.path.join(temp_dir, 'lambda_function.zip')
       urllib.request.urlretrieve(code_url, zip_path)
       
       # Extract the zip file
       extract_dir = os.path.join(temp_dir, 'extracted')
       os.makedirs(extract_dir)
       with zipfile.ZipFile(zip_path, 'r') as zip_ref:
           zip_ref.extractall(extract_dir)
       
       # Modify the lambda_embed.py file
       lambda_file_path = os.path.join(extract_dir, 'lambda_embed.py')
       with open(lambda_file_path, 'r') as file:
           content = file.read()
       
       # Make your changes here
       content = content.replace(
           'old_code',
           'new_code'
       )
       
       # Write the modified content back
       with open(lambda_file_path, 'w') as file:
           file.write(content)
       
       # Create a new zip file
       new_zip_path = os.path.join(temp_dir, 'new_lambda_function.zip')
       with zipfile.ZipFile(new_zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
           for root, dirs, files in os.walk(extract_dir):
               for file in files:
                   file_path = os.path.join(root, file)
                   arcname = os.path.relpath(file_path, extract_dir)
                   zipf.write(file_path, arcname)
       
       # Update the Lambda function
       with open(new_zip_path, 'rb') as f:
           lambda_client.update_function_code(
               FunctionName='lambda_embed',
               ZipFile=f.read(),
               Publish=True
           )
       
       print("Successfully updated Lambda function")

   finally:
       # Clean up
       shutil.rmtree(temp_dir)
   ```

2. **Run the script**:
   ```bash
   chmod +x update_lambda.py
   ./update_lambda.py
   ```

## Changing Bedrock Models

To change the Bedrock models used for embeddings or text generation:

1. **Check available models in your region**:
   ```bash
   aws bedrock list-foundation-models --region ap-south-1
   ```

2. **Update the model ID in the Lambda function code**:
   - For embeddings in `lambda_embed.py`:
     ```python
     model_id = "amazon.titan-embed-text-v2:0"  # Replace with your desired model
     ```
   
   - For text generation in `lambda_query.py`:
     ```python
     model_id = "anthropic.claude-3-5-sonnet-20240620-v1:0"  # Replace with your desired model
     ```

3. **Update the request format if needed**:
   Different models may require different request formats. For example:
   
   - For Titan models:
     ```python
     body = json.dumps({"inputText": text})
     ```
   
   - For Claude models:
     ```python
     body = json.dumps({
         "anthropic_version": "bedrock-2023-05-31",
         "max_tokens": 1000,
         "messages": [
             {
                 "role": "user",
                 "content": prompt
             }
         ]
     })
     ```

4. **Enable model access in AWS Bedrock console**:
   - Log in to the AWS Management Console
   - Navigate to Amazon Bedrock
   - Go to "Model access" in the left navigation
   - Find your desired model and enable access
   - Click "Request model access"

## Modifying OpenSearch Configuration

To update the OpenSearch configuration:

1. **Update access policies**:
   ```bash
   aws opensearch update-domain-config \
     --domain-name rag-vector-store \
     --region ap-south-1 \
     --access-policies '{
       "Version": "2012-10-17",
       "Statement": [{
         "Effect": "Allow",
         "Principal": {"AWS": "*"},
         "Action": "es:*",
         "Resource": "arn:aws:es:ap-south-1:YOUR_ACCOUNT_ID:domain/rag-vector-store/*"
       }]
     }'
   ```

2. **Update master user credentials**:
   ```bash
   aws opensearch update-domain-config \
     --domain-name rag-vector-store \
     --region ap-south-1 \
     --advanced-security-options '{
       "MasterUserOptions": {
         "MasterUserName": "admin",
         "MasterUserPassword": "YourNewPassword"
       }
     }'
   ```

3. **Update the OpenSearch client in Lambda functions**:
   ```python
   opensearch = OpenSearch(
       hosts=[{'host': host, 'port': 443}],
       http_auth=('admin', 'YourNewPassword'),  # Update credentials
       use_ssl=True,
       verify_certs=True,
       connection_class=RequestsHttpConnection
   )
   ```

## Troubleshooting

### Common Issues and Solutions

1. **Authorization Errors with OpenSearch**:
   - Check that the Lambda execution role is included in the OpenSearch access policy
   - Verify that the correct credentials are being used in the Lambda function
   - Ensure the OpenSearch domain is in the "Active" state

2. **Model Access Errors with Bedrock**:
   - Verify that you have enabled access to the model in the Bedrock console
   - Check that the Lambda execution role has the necessary permissions
   - Ensure you're using the correct model ID for your region

3. **Lambda Deployment Errors**:
   - Check that your deployment package includes all necessary dependencies
   - Verify that the total size of the package is within Lambda limits
   - Ensure the Lambda execution role has permissions to access all required services

4. **Vector Dimension Mismatch**:
   - Ensure the embedding dimension in OpenSearch matches the output of your embedding model
   - Add code to handle dimension mismatches by padding or truncating vectors

### Checking Lambda Logs

To check the Lambda function logs for errors:

```bash
# Get the latest log stream
LOG_STREAM=$(aws logs describe-log-streams \
  --log-group-name "/aws/lambda/lambda_embed" \
  --order-by LastEventTime \
  --descending \
  --limit 1 \
  --query "logStreams[0].logStreamName" \
  --output text)

# Get the log events
aws logs get-log-events \
  --log-group-name "/aws/lambda/lambda_embed" \
  --log-stream-name "$LOG_STREAM" \
  --limit 20
```

### Testing API Gateway

To test the API Gateway endpoint:

```bash
curl -X POST \
  https://tfyhelhcfc.execute-api.ap-south-1.amazonaws.com/prod/query \
  -H 'Content-Type: application/json' \
  -d '{"query": "What are Ninad'\''s technical skills?"}'
```
