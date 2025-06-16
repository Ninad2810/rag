import boto3
import json
import os
from opensearchpy import OpenSearch, RequestsHttpConnection
from requests_aws4auth import AWS4Auth

# Initialize clients
bedrock_runtime = boto3.client('bedrock-runtime')
region = os.environ['REGION']  # Changed from AWS_REGION to REGION

# OpenSearch configuration
host = os.environ['OPENSEARCH_ENDPOINT']
index_name = 'document_embeddings'
credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(credentials.access_key, credentials.secret_key,
                  region, 'es', session_token=credentials.token)

# Update OpenSearch client to use basic authentication
opensearch = OpenSearch(
    hosts=[{'host': host, 'port': 443}],
    http_auth=('admin', 'Admin@123456'),  # Using master user credentials
    use_ssl=True,
    verify_certs=True,
    connection_class=RequestsHttpConnection
)

# Generate embeddings using Amazon Bedrock
def generate_embedding(text):
    try:
        model_id = "amazon.titan-embed-text-v2:0"  # Updated model ID
        body = json.dumps({"inputText": text})

        response = bedrock_runtime.invoke_model(
            modelId=model_id,
            body=body
        )

        response_body = json.loads(response['body'].read())
        embedding = response_body.get('embedding')
        
        if not embedding:
            print(f"Warning: No embedding returned for text: {text[:50]}...")
            # Return a default embedding of zeros as fallback
            return [0.0] * 1536
            
        return embedding
    except Exception as e:
        print(f"Error generating embedding: {str(e)}")
        # Return a default embedding of zeros as fallback
        return [0.0] * 1536

# Search OpenSearch for relevant chunks
def search_documents(query_embedding, top_k=3):
    try:
        # Make sure the embedding dimension matches the index configuration (1536)
        if len(query_embedding) != 1536:
            # Pad or truncate to match required dimension
            if len(query_embedding) < 1536:
                query_embedding = query_embedding + [0.0] * (1536 - len(query_embedding))
            else:
                query_embedding = query_embedding[:1536]
        
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

        try:
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
            
            print(f"Found {len(results)} relevant chunks")
            if results:
                print(f"Top result (first 100 chars): {results[0]['text'][:100]}")
                
            return results
        except Exception as e:
            print(f"KNN search failed: {str(e)}")
            # Fall back to match_all query
            fallback_query = {
                "size": top_k,
                "query": {
                    "match_all": {}
                }
            }
            response = opensearch.search(
                body=fallback_query,
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
            return results
    except Exception as e:
        print(f"Search error: {str(e)}")
        return []

# Generate response using Amazon Bedrock
def generate_response(query, context_chunks):
    try:
        # If no context chunks, return a message
        if not context_chunks:
            return "I couldn't find any relevant information to answer your question."
            
        # Use Claude 3 Haiku which should be available in your region
        model_id = "anthropic.claude-3-haiku-20240307-v1:0"
        
        # Combine context chunks
        context = "\n\n".join([chunk['text'] for chunk in context_chunks])
        
        # Create prompt
        prompt = f"""
        Human: I need you to answer a question based on the following context information.
        Only use information from the provided context to answer the question.
        If you don't know the answer or can't find it in the context, just say so.
        Be concise and to the point.
        
        Do not mention that you're using context information or that your knowledge is limited.
        Just answer as if you know the information directly.

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
    except Exception as e:
        print(f"Error generating response with LLM: {str(e)}")
        # Fallback to simple response
        return f"Based on the available information:\n\n{context[:500]}..."

# Lambda handler
def lambda_handler(event, context):
    try:
        print(f"Received event: {json.dumps(event)}")
        
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        query = body.get('query')

        if not query:
            return {
                'statusCode': 400,
                'body': json.dumps('No query provided')
            }
            
        print(f"Processing query: {query}")

        # Generate embedding for the query
        query_embedding = generate_embedding(query)

        # Search for relevant chunks
        relevant_chunks = search_documents(query_embedding)

        # Generate response using LLM
        response = generate_response(query, relevant_chunks)
        print(f"Generated response (first 100 chars): {response[:100]}")

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
