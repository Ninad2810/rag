# RAG System Troubleshooting Guide

This guide provides solutions for common issues you might encounter with the RAG system.

## Table of Contents
1. [OpenSearch Issues](#opensearch-issues)
2. [Lambda Function Issues](#lambda-function-issues)
3. [Bedrock Model Issues](#bedrock-model-issues)
4. [API Gateway Issues](#api-gateway-issues)
5. [Document Processing Issues](#document-processing-issues)
6. [Query Response Issues](#query-response-issues)

## OpenSearch Issues

### Authorization Errors

**Symptoms:**
- Error messages containing `AuthorizationException` or `security_exception`
- 403 Forbidden responses from OpenSearch

**Solutions:**
1. **Check access policies**:
   ```bash
   aws opensearch describe-domain-config --domain-name rag-vector-store --region ap-south-1
   ```

2. **Update access policies** to include all necessary roles:
   ```bash
   aws opensearch update-domain-config \
     --domain-name rag-vector-store \
     --region ap-south-1 \
     --access-policies '{
       "Version": "2012-10-17",
       "Statement": [{
         "Effect": "Allow",
         "Principal": {"AWS": "*"},
         "Action": "es:*",
         "Resource": "arn:aws:es:ap-south-1:YOUR_ACCOUNT_ID:domain/rag-vector-store/*"
       }]
     }'
   ```

3. **Update Lambda functions** to use basic authentication:
   ```python
   opensearch = OpenSearch(
       hosts=[{'host': host, 'port': 443}],
       http_auth=('admin', 'Admin@123456'),  # Use basic auth
       use_ssl=True,
       verify_certs=True,
       connection_class=RequestsHttpConnection
   )
   ```

### Index Not Found

**Symptoms:**
- Error messages containing `index_not_found_exception`
- No results returned from queries

**Solutions:**
1. **Check if the index exists**:
   ```bash
   curl -X HEAD -u "admin:Admin@123456" \
     "https://search-rag-vector-store-pxl6wwymour3to2mnlygpheypm.ap-south-1.es.amazonaws.com/document_embeddings"
   ```

2. **Create the index manually** if needed:
   ```bash
   curl -X PUT -u "admin:Admin@123456" \
     "https://search-rag-vector-store-pxl6wwymour3to2mnlygpheypm.ap-south-1.es.amazonaws.com/document_embeddings" \
     -H 'Content-Type: application/json' \
     -d '{
       "settings": {
         "index": {
           "knn": true
         }
       },
       "mappings": {
         "properties": {
           "embedding": {
             "type": "knn_vector",
             "dimension": 1536
           },
           "text": {"type": "text"},
           "document_id": {"type": "keyword"},
           "chunk_id": {"type": "keyword"},
           "metadata": {"type": "object"}
         }
       }
     }'
   ```

### Vector Dimension Mismatch

**Symptoms:**
- Error messages containing `mapper_parsing_exception` or `vector has invalid dimension`
- Failed document indexing

**Solutions:**
1. **Check the embedding dimension** in your OpenSearch index:
   ```bash
   curl -X GET -u "admin:Admin@123456" \
     "https://search-rag-vector-store-pxl6wwymour3to2mnlygpheypm.ap-south-1.es.amazonaws.com/document_embeddings/_mapping" | jq
   ```

2. **Ensure the embedding vectors match the expected dimension**:
   ```python
   # Add this code to handle dimension mismatches
   if len(embedding) != 1536:  # Adjust based on your index configuration
       if len(embedding) < 1536:
           embedding = embedding + [0.0] * (1536 - len(embedding))
       else:
           embedding = embedding[:1536]
   ```

## Lambda Function Issues

### Timeout Errors

**Symptoms:**
- Task timed out after X seconds
- Incomplete processing of documents

**Solutions:**
1. **Increase the Lambda timeout**:
   ```bash
   aws lambda update-function-configuration \
     --function-name lambda_embed \
     --timeout 300 \
     --region ap-south-1
   ```

2. **Process larger documents in smaller chunks**:
   ```python
   # Reduce chunk size for better processing
   chunks = chunk_text(text, chunk_size=300, overlap=50)
   ```

### Memory Errors

**Symptoms:**
- Out of memory errors
- Function crashes with large documents

**Solutions:**
1. **Increase Lambda memory**:
   ```bash
   aws lambda update-function-configuration \
     --function-name lambda_embed \
     --memory-size 2048 \
     --region ap-south-1
   ```

2. **Optimize memory usage** in your code:
   ```python
   # Process documents in batches
   batch_size = 10
   for i in range(0, len(chunks), batch_size):
       batch = chunks[i:i+batch_size]
       # Process batch
   ```

### Permission Issues

**Symptoms:**
- Access denied errors
- Unable to access S3, Bedrock, or OpenSearch

**Solutions:**
1. **Check Lambda execution role**:
   ```bash
   aws lambda get-function --function-name lambda_embed --region ap-south-1 | jq .Configuration.Role
   ```

2. **Add necessary permissions** to the role:
   ```bash
   aws iam attach-role-policy \
     --role-name lambda-embed-role \
     --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
   
   aws iam attach-role-policy \
     --role-name lambda-embed-role \
     --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/bedrock-runtime-access-policy
   ```

## Bedrock Model Issues

### Model Access Errors

**Symptoms:**
- Error messages containing `AccessDeniedException` or `The provided model identifier is invalid`
- Failed embedding generation

**Solutions:**
1. **Check available models** in your region:
   ```bash
   aws bedrock list-foundation-models --region ap-south-1
   ```

2. **Enable model access** in the AWS Bedrock console:
   - Navigate to Amazon Bedrock in the AWS Console
   - Go to "Model access" in the left navigation
   - Find and enable the models you need

3. **Update IAM policies** to allow Bedrock access:
   ```bash
   aws iam put-role-policy \
     --role-name lambda-embed-role \
     --policy-name bedrock-access \
     --policy-document '{
       "Version": "2012-10-17",
       "Statement": [
         {
           "Effect": "Allow",
           "Action": [
             "bedrock:ListFoundationModels",
             "bedrock:GetFoundationModel",
             "bedrock-runtime:InvokeModel"
           ],
           "Resource": "*"
         }
       ]
     }'
   ```

### Model Response Format Issues

**Symptoms:**
- Unexpected response formats
- Missing fields in model responses

**Solutions:**
1. **Check model documentation** for the correct request and response formats
2. **Add error handling** for model responses:
   ```python
   try:
       response_body = json.loads(response['body'].read())
       embedding = response_body.get('embedding')
       
       if not embedding:
           print(f"Warning: No embedding returned")
           return [0.0] * 1536  # Return default embedding
           
       return embedding
   except Exception as e:
       print(f"Error processing model response: {str(e)}")
       return [0.0] * 1536  # Return default embedding
   ```

## API Gateway Issues

### CORS Errors

**Symptoms:**
- Browser console errors about CORS
- Unable to access API from web applications

**Solutions:**
1. **Enable CORS** in API Gateway:
   ```bash
   aws apigateway update-resource \
     --rest-api-id YOUR_API_ID \
     --resource-id YOUR_RESOURCE_ID \
     --patch-operations '[
       {
         "op": "replace",
         "path": "/corsConfiguration",
         "value": "{\"allowOrigins\": [\"*\"], \"allowMethods\": [\"POST\", \"OPTIONS\"], \"allowHeaders\": [\"Content-Type\", \"Authorization\"]}"
       }
     ]'
   ```

2. **Add CORS headers** in Lambda response:
   ```python
   return {
       'statusCode': 200,
       'headers': {
           'Content-Type': 'application/json',
           'Access-Control-Allow-Origin': '*',
           'Access-Control-Allow-Headers': 'Content-Type,Authorization',
           'Access-Control-Allow-Methods': 'POST,OPTIONS'
       },
       'body': json.dumps({
           'response': response,
           'sources': [chunk['document_id'] for chunk in relevant_chunks]
       })
   }
   ```

### Authentication Errors

**Symptoms:**
- "Missing Authentication Token" errors
- 403 Forbidden responses

**Solutions:**
1. **Check API Gateway configuration**:
   ```bash
   aws apigateway get-method \
     --rest-api-id YOUR_API_ID \
     --resource-id YOUR_RESOURCE_ID \
     --http-method POST
   ```

2. **If using API keys**, include them in requests:
   ```bash
   curl -X POST \
     https://tfyhelhcfc.execute-api.ap-south-1.amazonaws.com/prod/query \
     -H 'Content-Type: application/json' \
     -H 'x-api-key: YOUR_API_KEY' \
     -d '{"query": "What are Ninad'\''s technical skills?"}'
   ```

## Document Processing Issues

### PDF Extraction Errors

**Symptoms:**
- Empty or incomplete text extraction
- Missing content in processed documents

**Solutions:**
1. **Check PDF extraction code**:
   ```python
   def extract_text_from_pdf(file_content):
       try:
           pdf_reader = PyPDF2.PdfReader(io.BytesIO(file_content))
           text = ""
           for page in pdf_reader.pages:
               text += page.extract_text() + "\n"
           
           if not text.strip():
               print("Warning: Extracted text is empty")
               
           return text
       except Exception as e:
           print(f"Error extracting text from PDF: {str(e)}")
           return ""
   ```

2. **Try alternative PDF extraction libraries**:
   ```bash
   pip install pdfminer.six
   ```
   
   ```python
   from pdfminer.high_level import extract_text_to_fp
   from pdfminer.layout import LAParams
   import io
   
   def extract_text_from_pdf(file_content):
       output = io.StringIO()
       with io.BytesIO(file_content) as pdf_file:
           extract_text_to_fp(pdf_file, output, laparams=LAParams())
       return output.getvalue()
   ```

### Large Document Handling

**Symptoms:**
- Timeouts when processing large documents
- Incomplete processing

**Solutions:**
1. **Process documents in smaller chunks**:
   ```python
   # Process large documents page by page
   for i, page in enumerate(pdf_reader.pages):
       page_text = page.extract_text()
       page_chunks = chunk_text(page_text)
       index_chunks(f"{document_id}_page_{i}", page_chunks)
   ```

2. **Implement asynchronous processing** for large documents:
   - Upload document to S3
   - Trigger Lambda function via S3 event
   - Process document asynchronously
   - Store results in OpenSearch

## Query Response Issues

### Poor Search Results

**Symptoms:**
- Irrelevant search results
- Missing information in responses

**Solutions:**
1. **Improve chunking strategy**:
   ```python
   def chunk_text(text, chunk_size=300, overlap=50):
       # Use semantic boundaries like paragraphs or sentences
       paragraphs = text.split('\n\n')
       chunks = []
       
       current_chunk = []
       current_size = 0
       
       for paragraph in paragraphs:
           paragraph_size = len(paragraph.split())
           
           if current_size + paragraph_size <= chunk_size:
               current_chunk.append(paragraph)
               current_size += paragraph_size
           else:
               if current_chunk:
                   chunks.append('\n\n'.join(current_chunk))
               current_chunk = [paragraph]
               current_size = paragraph_size
       
       if current_chunk:
           chunks.append('\n\n'.join(current_chunk))
           
       return chunks
   ```

2. **Adjust search parameters**:
   ```python
   search_query = {
       "size": top_k,
       "query": {
           "bool": {
               "should": [
                   {
                       "knn": {
                           "embedding": {
                               "vector": query_embedding,
                               "k": top_k
                           }
                       }
                   },
                   {
                       "match": {
                           "text": query
                       }
                   }
               ]
           }
       }
   }
   ```

### Response Formatting Issues

**Symptoms:**
- Raw context in responses
- Poorly formatted answers

**Solutions:**
1. **Improve prompt engineering**:
   ```python
   prompt = f"""
   Human: I need you to answer a question based on the following context information.
   Only use information from the provided context to answer the question.
   If you don't know the answer or can't find it in the context, just say so.
   
   Format your answer as a clear, concise response. Do not mention that you're using context information.
   Do not include the raw context in your response.
   
   Context:
   {context}
   
   Question: {query}
   """
   ```

2. **Post-process model responses** if needed:
   ```python
   def clean_response(response):
       # Remove any mentions of context
       response = re.sub(r'Based on the (provided |available |given )?context', '', response)
       response = re.sub(r'According to the (provided |available |given )?context', '', response)
       
       # Remove any raw context that might have been included
       if "This is the raw context information" in response:
           response = response.split("This is the raw context information")[0]
           
       return response.strip()
   ```
