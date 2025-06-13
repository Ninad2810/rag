# RAG System

This is a Retrieval-Augmented Generation (RAG) system that uses AWS services to process documents and answer questions based on their content.

## Files

- `rag_admin.py`: Script to upload and process documents
- `api_test.py`: Script to test the API Gateway endpoint
- `test_query_interactive.py`: Interactive script to query the system directly through Lambda
- `lambda_embed.py`: Lambda function code for embedding documents
- `lambda_query.py`: Lambda function code for querying documents

## Usage

### Processing Documents

```bash
# Upload a document to S3
./rag_admin.py upload path/to/document.pdf

# Process a document (generate embeddings and index in OpenSearch)
./rag_admin.py process docs/document.pdf
```

### Querying

```bash
# Query using the interactive script
./test_query_interactive.py --query "Your question here"

# Query using the API test script
./api_test.py --query "Your question here"
```

### API Endpoint

The API Gateway endpoint is:
```
https://tfyhelhcfc.execute-api.ap-south-1.amazonaws.com/prod/query
```

Send POST requests with a JSON body:
```json
{
  "query": "Your question here"
}
```

### OpenSearch Dashboard

Access the OpenSearch dashboard at:
```
https://search-rag-vector-store-pxl6wwymour3to2mnlygpheypm.ap-south-1.es.amazonaws.com/_dashboards/
```

Credentials:
- Username: admin
- Password: Admin@123456
