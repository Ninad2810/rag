#!/usr/bin/env python3
import requests
import json
import argparse

def query_api(query_text, api_url):
    """
    Query the RAG system through the API Gateway
    """
    headers = {
        'Content-Type': 'application/json'
    }
    
    payload = {
        'query': query_text
    }
    
    try:
        response = requests.post(api_url, headers=headers, json=payload)
        
        # Check if the request was successful
        if response.status_code == 200:
            data = response.json()
            print("\n" + "="*80)
            print("QUERY RESPONSE:")
            print("="*80)
            print(data.get('response', 'No response generated'))
            print("\n" + "-"*80)
            print("SOURCES:")
            for source in data.get('sources', []):
                print(f"- {source}")
            print("="*80 + "\n")
        else:
            print(f"Error: HTTP {response.status_code}")
            print(response.text)
            
    except Exception as e:
        print(f"Error querying API: {str(e)}")

def main():
    parser = argparse.ArgumentParser(description='Query the RAG system through API Gateway')
    parser.add_argument('--query', '-q', help='Query text (optional)')
    parser.add_argument('--api', '-a', default='https://tfyhelhcfc.execute-api.ap-south-1.amazonaws.com/prod/query', 
                        help='API Gateway URL')
    args = parser.parse_args()
    
    if args.query:
        query_api(args.query, args.api)
    else:
        print("Interactive RAG API Query System")
        print("Type 'exit' or 'quit' to end the session")
        print(f"Using API endpoint: {args.api}")
        
        while True:
            query = input("\nEnter your query: ")
            if query.lower() in ['exit', 'quit']:
                break
            
            query_api(query, args.api)

if __name__ == '__main__':
    main()
