#!/usr/bin/env python3
"""
RAG System Testing and Debugging Script
This script helps test and debug your RAG system by providing various testing utilities.
"""

import boto3
import json
import os
import sys
import argparse
from opensearchpy import OpenSearch, RequestsHttpConnection
from requests_aws4auth import AWS4Auth

class RAGTester:
    def __init__(self, region='us-east-1'):
        self.region = region
        self.bedrock_runtime = boto3.client('bedrock-runtime', region_name=region)
        
        # OpenSearch configuration
        self.host = os.environ.get('OPENSEARCH_ENDPOINT')
        if not self.host:
            print("Warning: OPENSEARCH_ENDPOINT environment variable not set")
            return
            
        self.index_name = 'document_embeddings'
        credentials = boto3.Session().get_credentials()
        awsauth = AWS4Auth(credentials.access_key, credentials.secret_key,
                          region, 'es', session_token=credentials.token)

        self.opensearch = OpenSearch(
            hosts=[{'host': self.host, 'port': 443}],
            http_auth=awsauth,
            use_ssl=True,
            verify_certs=True,
            connection_class=RequestsHttpConnection
        )

    def test_opensearch_connection(self):
        """Test OpenSearch connection and index status"""
        try:
            # Check cluster health
            health = self.opensearch.cluster.health()
            print(f"✅ OpenSearch cluster status: {health['status']}")
            
            # Check if index exists
            if self.opensearch.indices.exists(index=self.index_name):
                # Get index stats
                stats = self.opensearch.indices.stats(index=self.index_name)
                doc_count = stats['indices'][self.index_name]['total']['docs']['count']
                print(f"✅ Index '{self.index_name}' exists with {doc_count} documents")
                
                # Sample a few documents
                sample = self.opensearch.search(
                    index=self.index_name,
                    body={"size": 3, "query": {"match_all": {}}},
                    _source=["document_id", "chunk_id", "metadata"]
                )
                
                print("\n📄 Sample documents in index:")
                for hit in sample['hits']['hits']:
                    source = hit['_source']
                    print(f"  - Document: {source['document_id']}")
                    print(f"    Chunk: {source['chunk_id']}")
                    if 'metadata' in source:
                        print(f"    Page: {source['metadata'].get('page_number', 'N/A')}")
                        print(f"    Words: {source['metadata'].get('word_count', 'N/A')}")
                
            else:
                print(f"❌ Index '{self.index_name}' does not exist")
                
        except Exception as e:
            print(f"❌ OpenSearch connection failed: {str(e)}")

    def generate_embedding(self, text):
        """Generate embedding for text"""
        model_id = "amazon.titan-embed-text-v1"
        body = json.dumps({"inputText": text})

        response = self.bedrock_runtime.invoke_model(
            modelId=model_id,
            body=body
        )

        response_body = json.loads(response['body'].read())
        return response_body['embedding']

    def test_embedding_generation(self, test_text="This is a test document about machine learning."):
        """Test embedding generation"""
        try:
            embedding = self.generate_embedding(test_text)
            print(f"✅ Embedding generated successfully")
            print(f"   Dimension: {len(embedding)}")
            print(f"   Sample values: {embedding[:5]}")
            return embedding
        except Exception as e:
            print(f"❌ Embedding generation failed: {str(e)}")
            return None

    def test_search_functionality(self, query="machine learning"):
        """Test search functionality with a query"""
        try:
            print(f"\n🔍 Testing search for: '{query}'")
            
            # Generate query embedding
            query_embedding = self.generate_embedding(query)
            
            # KNN search
            search_query = {
                "size": 5,
                "query": {
                    "knn": {
                        "embedding": {
                            "vector": query_embedding,
                            "k": 5
                        }
                    }
                }
            }

            response = self.opensearch.search(
                body=search_query,
                index=self.index_name
            )

            print(f"✅ Search completed. Found {len(response['hits']['hits'])} results:")
            
            for i, hit in enumerate(response['hits']['hits'], 1):
                source = hit['_source']
                score = hit['_score']
                print(f"\n  Result {i} (Score: {score:.4f}):")
                print(f"    Document: {source['document_id']}")
                print(f"    Chunk: {source['chunk_id']}")
                print(f"    Text preview: {source['text'][:150]}...")
                
            return response['hits']['hits']
            
        except Exception as e:
            print(f"❌ Search test failed: {str(e)}")
            return []

    def test_lambda_query(self, query, lambda_function_name):
        """Test the query Lambda function directly"""
        try:
            lambda_client = boto3.client('lambda')
            
            payload = {
                'body': json.dumps({'query': query})
            }

            print(f"\n🚀 Testing Lambda function: {lambda_function_name}")
            print(f"   Query: '{query}'")
            
            response = lambda_client.invoke(
                FunctionName=lambda_function_name,
                InvocationType='RequestResponse',
                Payload=json.dumps(payload)
            )

            response_payload = json.loads(response['Payload'].read().decode('utf-8'))
            
            if response_payload.get('statusCode') == 200:
                body = json.loads(response_payload['body'])
                print(f"✅ Lambda response successful:")
                print(f"   Response: {body.get('response', 'No response')}")
                print(f"   Sources: {body.get('sources', [])}")
                if 'debug_info' in body:
                    print(f"   Debug: {body['debug_info']}")
            else:
                print(f"❌ Lambda error: {response_payload}")
                
        except Exception as e:
            print(f"❌ Lambda test failed: {str(e)}")

    def test_different_queries(self, lambda_function_name):
        """Test with different types of queries"""
        test_queries = [
            "What is machine learning?",
            "How does artificial intelligence work?", 
            "Tell me about data science",
            "What are neural networks?",
            "Explain deep learning algorithms"
        ]
        
        print("\n🧪 Testing different query types:")
        for query in test_queries:
            print(f"\n--- Testing: '{query}' ---")
            self.test_lambda_query(query, lambda_function_name)

    def analyze_document_distribution(self):
        """Analyze how documents are distributed in the index"""
        try:
            # Get document distribution
            agg_query = {
                "size": 0,
                "aggs": {
                    "documents": {
                        "terms": {
                            "field": "document_id",
                            "size": 50
                        }
                    }
                }
            }
            
            response = self.opensearch.search(
                body=agg_query,
                index=self.index_name
            )
            
            print("\n📊 Document distribution in index:")
            for bucket in response['aggregations']['documents']['buckets']:
                doc_id = bucket['key']
                count = bucket['doc_count']
                print(f"  {doc_id}: {count} chunks")
                
        except Exception as e:
            print(f"❌ Document analysis failed: {str(e)}")

def main():
    parser = argparse.ArgumentParser(description='RAG System Tester')
    parser.add_argument('--region', default='us-east-1', help='AWS region')
    parser.add_argument('--lambda-function', default='lambda_query', help='Query Lambda function name')
    parser.add_argument('--query', help='Specific query to test')
    parser.add_argument('--full-test', action='store_true', help='Run full test suite')
    
    args = parser.parse_args()
    
    # Check for required environment variables
    if not os.environ.get('OPENSEARCH_ENDPOINT'):
        print("❌ OPENSEARCH_ENDPOINT environment variable is required")
        sys.exit(1)
    
    tester = RAGTester(region=args.region)
    
    if args.full_test:
        print("🔍 Running full RAG system test suite...\n")
        tester.test_opensearch_connection()
        tester.test_embedding_generation()
        tester.analyze_document_distribution()
        tester.test_search_functionality()
        tester.test_different_queries(args.lambda_function)
    elif args.query:
        tester.test_lambda_query(args.query, args.lambda_function)
    else:
        print("🔍 Running basic connectivity tests...\n")
        tester.test_opensearch_connection()
        tester.test_embedding_generation()
        tester.test_search_functionality()

if __name__ == '__main__':
    main()