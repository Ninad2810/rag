import boto3
import json
import os
import PyPDF2
import io
import re
from opensearchpy import OpenSearch, RequestsHttpConnection
from requests_aws4auth import AWS4Auth

# Initialize clients
s3 = boto3.client('s3')
bedrock_runtime = boto3.client('bedrock-runtime')
region = os.environ['AWS_REGION']

# OpenSearch configuration
host = os.environ['OPENSEARCH_ENDPOINT']
index_name = 'document_embeddings'
credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(credentials.access_key, credentials.secret_key,
                  region, 'es', session_token=credentials.token)

opensearch = OpenSearch(
    hosts=[{'host': host, 'port': 443}],
    http_auth=awsauth,
    use_ssl=True,
    verify_certs=True,
    connection_class=RequestsHttpConnection
)

# Create index if it doesn't exist
def create_index_if_not_exists():
    if not opensearch.indices.exists(index=index_name):
        index_body = {
            'settings': {
                'index': {
                    'knn': True,
                }
            },
            'mappings': {
                'properties': {
                    'embedding': {
                        'type': 'knn_vector',
                        'dimension': 1536  # Adjust based on your embedding model
                    },
                    'text': {'type': 'text'},
                    'document_id': {'type': 'keyword'},
                    'chunk_id': {'type': 'keyword'},
                    'metadata': {'type': 'object'}
                }
            }
        }
        opensearch.indices.create(index=index_name, body=index_body)

# Extract text from PDF
def extract_text_from_pdf(file_content):
    pdf_reader = PyPDF2.PdfReader(io.BytesIO(file_content))
    text = ""
    for page in pdf_reader.pages:
        text += page.extract_text() + "\n"
    return text

# Extract text based on file type
def extract_text(bucket, key):
    response = s3.get_object(Bucket=bucket, Key=key)
    file_content = response['Body'].read()

    if key.lower().endswith('.pdf'):
        return extract_text_from_pdf(file_content)
    elif key.lower().endswith('.txt'):
        return file_content.decode('utf-8')
    else:
        raise ValueError(f"Unsupported file type: {key}")

# Chunk text into smaller segments
def chunk_text(text, chunk_size=500, overlap=100):
    words = text.split()
    chunks = []

    for i in range(0, len(words), chunk_size - overlap):
        chunk = ' '.join(words[i:i + chunk_size])
        chunks.append(chunk)

    return chunks

# Generate embeddings using Amazon Bedrock
def generate_embedding(text):
    model_id = "amazon.titan-embed-text-v1"
    body = json.dumps({"inputText": text})

    response = bedrock_runtime.invoke_model(
        modelId=model_id,
        body=body
    )

    response_body = json.loads(response['body'].read())
    return response_body['embedding']

# Index chunks to OpenSearch
def index_chunks(document_id, chunks):
    for i, chunk in enumerate(chunks):
        embedding = generate_embedding(chunk)

        document = {
            'embedding': embedding,
            'text': chunk,
            'document_id': document_id,
            'chunk_id': f"{document_id}_{i}",
            'metadata': {
                'source': document_id,
                'chunk_number': i
            }
        }

        opensearch.index(
            index=index_name,
            body=document,
            id=f"{document_id}_{i}"
        )

# Lambda handler
def lambda_handler(event, context):
    try:
        # Get bucket and key from event
        if 'Records' in event:  # S3 event notification
            bucket = event['Records'][0]['s3']['bucket']['name']
            key = event['Records'][0]['s3']['object']['key']
        else:  # Direct invocation
            bucket = os.environ['DOCUMENT_BUCKET']
            key = event.get('key')

        if not key:
            return {
                'statusCode': 400,
                'body': json.dumps('No document key provided')
            }

        # Create index if it doesn't exist
        create_index_if_not_exists()

        # Extract text from document
        text = extract_text(bucket, key)

        # Chunk the text
        chunks = chunk_text(text)

        # Generate document ID from the key
        document_id = re.sub(r'[^a-zA-Z0-9]', '_', key)

        # Index chunks to OpenSearch
        index_chunks(document_id, chunks)

        return {
            'statusCode': 200,
            'body': json.dumps(f'Successfully processed document {key}')
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error processing document: {str(e)}')
        }