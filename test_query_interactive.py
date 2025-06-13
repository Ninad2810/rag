#!/usr/bin/env python3
import boto3
import json
import argparse

def query_rag_system(query_text):
    """
    Query the RAG system with the given text
    """
    # Initialize Lambda client
    lambda_client = boto3.client('lambda', region_name='ap-south-1')
    
    try:
        # Invoke Lambda function
        response = lambda_client.invoke(
            FunctionName='lambda_query',
            InvocationType='RequestResponse',
            Payload=json.dumps({
                'body': json.dumps({
                    'query': query_text
                })
            })
        )
        
        # Parse response
        response_payload = json.loads(response['Payload'].read().decode('utf-8'))
        
        # Check if the response was successful
        if response_payload.get('statusCode') == 200:
            body = json.loads(response_payload.get('body', '{}'))
            print("\n" + "="*80)
            print("QUERY RESPONSE:")
            print("="*80)
            print(body.get('response', 'No response generated'))
            print("\n" + "-"*80)
            print("SOURCES:")
            for source in body.get('sources', []):
                print(f"- {source}")
            print("="*80 + "\n")
        else:
            print(f"Error: {response_payload}")
            
    except Exception as e:
        print(f"Error querying RAG system: {str(e)}")

def main():
    parser = argparse.ArgumentParser(description='Query the RAG system')
    parser.add_argument('--query', '-q', help='Query text (optional)')
    args = parser.parse_args()
    
    if args.query:
        query_rag_system(args.query)
    else:
        print("Interactive RAG Query System")
        print("Type 'exit' or 'quit' to end the session")
        
        while True:
            query = input("\nEnter your query: ")
            if query.lower() in ['exit', 'quit']:
                break
            
            query_rag_system(query)

if __name__ == '__main__':
    main()
