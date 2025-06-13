import boto3
import json
import os
from opensearchpy import OpenSearch, RequestsHttpConnection
from requests_aws4auth import AWS4Auth

# Initialize clients
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

# Search OpenSearch for relevant chunks
def search_documents(query_embedding, top_k=3):
    search_query = {
        "size": top_k,
        "query": {
            "knn": {
                "embedding": {
                    "vector": query_embedding,
                    "k": top_k
                }
            }
        }
    }

    response = opensearch.search(
        body=search_query,
        index=index_name
    )

    results = []
    for hit in response['hits']['hits']:
        results.append({
            'text': hit['_source']['text'],
            'score': hit['_score'],
            'document_id': hit['_source']['document_id'],
            'chunk_id': hit['_source']['chunk_id']
        })
    
    ############
    print(f"Top search hits: {[hit['_source']['text'][:100] for hit in response['hits']['hits']]}")
    ##############

    return results

# Generate response using Amazon Bedrock
def generate_response(query, context_chunks):
    model_id = "anthropic.claude-3-sonnet-20240229-v1:0"

    # Combine context chunks
    context = "\n\n".join([chunk['text'] for chunk in context_chunks])

    # Create prompt
    prompt = f"""
        Human: I need you to answer a question based on the following context information.
        Only use information from the provided context to answer the question.
        If you don't know the answer or can't find it in the context, just say so.

        Context:
        {context}

        Question: {query}
    """

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

    response = bedrock_runtime.invoke_model(
        modelId=model_id,
        body=body
    )

    response_body = json.loads(response['body'].read())
    return response_body['content'][0]['text']

# Lambda handler
def lambda_handler(event, context):
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        query = body.get('query')

        if not query:
            return {
                'statusCode': 400,
                'body': json.dumps('No query provided')
            }

        # Generate embedding for the query
        query_embedding = generate_embedding(query)

        # Search for relevant chunks
        relevant_chunks = search_documents(query_embedding)

        # Generate response using LLM
        response = generate_response(query, relevant_chunks)

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'response': response,
                'sources': [chunk['document_id'] for chunk in relevant_chunks]
            })
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error processing query: {str(e)}')
        }