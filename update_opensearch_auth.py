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

    # Update the OpenSearch client to use basic authentication
    content = content.replace(
        'opensearch = OpenSearch(\n    hosts=[{\'host\': host, \'port\': 443}],\n    http_auth=awsauth,\n    use_ssl=True,\n    verify_certs=True,\n    connection_class=RequestsHttpConnection\n)',
        '''opensearch = OpenSearch(
    hosts=[{'host': host, 'port': 443}],
    http_auth=('admin', 'Admin@123456'),  # Using master user credentials
    use_ssl=True,
    verify_certs=True,
    connection_class=RequestsHttpConnection
)'''
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

    print("Successfully updated Lambda function with basic authentication")

finally:
    # Clean up
    shutil.rmtree(temp_dir)
