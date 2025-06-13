#!/bin/bash

# Create a directory for essential files
mkdir -p essential_files

# Copy essential files to the new directory
cp README.md essential_files/
cp rag_admin.py essential_files/
cp api_test.py essential_files/
cp test_query_interactive.py essential_files/
cp lambda_embed.py essential_files/
cp lambda_query.py essential_files/
cp -r docs essential_files/ 2>/dev/null || mkdir -p essential_files/docs

# Copy any documents we've processed
cp Ninad_Lunge_Resume_New.pdf essential_files/docs/ 2>/dev/null
cp aws_services.txt essential_files/docs/ 2>/dev/null

# Create a README with instructions
cat > essential_files/README.md << 'EOF'
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
EOF

# Create a backup directory for other files
mkdir -p backup_files

# Move all other files to the backup directory
for file in $(ls -A | grep -v "essential_files" | grep -v "backup_files" | grep -v "cleanup.sh"); do
    if [ "$file" != "." ] && [ "$file" != ".." ]; then
        mv "$file" backup_files/ 2>/dev/null
    fi
done

# Move essential files back to the main directory
cp -r essential_files/* .

# Clean up
rm -rf essential_files

echo "Cleanup complete. Essential files kept in the main directory."
echo "All other files moved to the backup_files directory."
