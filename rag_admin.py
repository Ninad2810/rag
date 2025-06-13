#!/usr/bin/env python3
import argparse
import boto3
import os
import sys
import json

def upload_document(file_path, bucket_name):
   """Upload a document to S3 bucket"""
   if not os.path.exists(file_path):
       print(f"Error: File {file_path} does not exist")
       return False

   s3 = boto3.client('s3')
   file_name = os.path.basename(file_path)

   try:
       # Create the docs/ prefix if it doesn't exist
       s3.put_object(Bucket=bucket_name, Key='docs/', Body='')
       
       # Upload the file to the docs/ prefix
       s3.upload_file(file_path, bucket_name, f"docs/{file_name}")
       print(f"Successfully uploaded {file_name} to s3://{bucket_name}/docs/")
       return True
   except Exception as e:
       print(f"Error uploading file: {str(e)}")
       return False

def trigger_embedding(document_key, function_name):
   """Trigger Lambda function to embed document"""
   lambda_client = boto3.client('lambda')

   try:
       # Ensure the key has the docs/ prefix
       if not document_key.startswith('docs/'):
           document_key = f"docs/{document_key}"
           
       print(f"Triggering Lambda function {function_name} for document {document_key}")
       
       payload = {
           'key': document_key
       }

       response = lambda_client.invoke(
           FunctionName=function_name,
           InvocationType='RequestResponse',
           Payload=bytes(json.dumps(payload), 'utf-8')
       )

       response_payload = json.loads(response['Payload'].read().decode('utf-8'))
       print(f"Lambda response: {response_payload}")
       return True
   except Exception as e:
       print(f"Error triggering Lambda: {str(e)}")
       return False

def main():
   parser = argparse.ArgumentParser(description='RAG Admin CLI')
   subparsers = parser.add_subparsers(dest='command', help='Commands')

   # Upload command
   upload_parser = subparsers.add_parser('upload', help='Upload a document')
   upload_parser.add_argument('file', help='Path to the file to upload')
   upload_parser.add_argument('--bucket', default='rag-document-store-ninad-test', help='S3 bucket name')

   # Process command
   process_parser = subparsers.add_parser('process', help='Process a document')
   process_parser.add_argument('key', help='S3 key of the document')
   process_parser.add_argument('--function', default='lambda_embed', help='Lambda function name')

   # Parse arguments
   args = parser.parse_args()

   if args.command == 'upload':
       upload_document(args.file, args.bucket)
   elif args.command == 'process':
       trigger_embedding(args.key, args.function)
   else:
       parser.print_help()

if __name__ == '__main__':
   main()
