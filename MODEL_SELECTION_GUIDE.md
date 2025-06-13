# AWS Bedrock Model Selection Guide

This guide provides information on selecting and using different AWS Bedrock models for your RAG system.

## Table of Contents
1. [Available Model Types](#available-model-types)
2. [Embedding Models](#embedding-models)
3. [Text Generation Models](#text-generation-models)
4. [Model Performance Considerations](#model-performance-considerations)
5. [Cost Considerations](#cost-considerations)
6. [Region Availability](#region-availability)

## Available Model Types

AWS Bedrock offers several types of models:

1. **Embedding Models**: Generate vector representations of text for semantic search
2. **Text Generation Models**: Generate human-like text responses
3. **Image Generation Models**: Generate images from text descriptions
4. **Multimodal Models**: Process both text and images

For a RAG system, you'll primarily use embedding models and text generation models.

## Embedding Models

Embedding models convert text into numerical vectors that capture semantic meaning. These vectors are used for similarity search in OpenSearch.

### Recommended Embedding Models

| Model ID | Description | Dimension | Best For |
|----------|-------------|-----------|----------|
| `amazon.titan-embed-text-v2:0` | Titan Text Embeddings V2 | 1536 | General purpose text embeddings |
| `cohere.embed-english-v3` | Cohere Embed English | 1024 | English-only content |
| `cohere.embed-multilingual-v3` | Cohere Embed Multilingual | 1024 | Multilingual content |

### Example Code for Titan Embeddings

```python
def generate_embedding(text):
    model_id = "amazon.titan-embed-text-v2:0"
    body = json.dumps({"inputText": text})

    response = bedrock_runtime.invoke_model(
        modelId=model_id,
        body=body
    )

    response_body = json.loads(response['body'].read())
    return response_body['embedding']
```

### Example Code for Cohere Embeddings

```python
def generate_embedding(text):
    model_id = "cohere.embed-english-v3"
    body = json.dumps({
        "texts": [text],
        "input_type": "search_document"
    })

    response = bedrock_runtime.invoke_model(
        modelId=model_id,
        body=body
    )

    response_body = json.loads(response['body'].read())
    return response_body['embeddings'][0]
```

## Text Generation Models

Text generation models produce human-like text responses based on prompts. These are used to generate answers from retrieved context.

### Recommended Text Generation Models

| Model ID | Description | Context Window | Best For |
|----------|-------------|---------------|----------|
| `anthropic.claude-3-haiku-20240307-v1:0` | Claude 3 Haiku | 48K tokens | Fast, cost-effective responses |
| `anthropic.claude-3-sonnet-20240229-v1:0` | Claude 3 Sonnet | 28K tokens | Balanced performance and quality |
| `anthropic.claude-3-5-sonnet-20240620-v1:0` | Claude 3.5 Sonnet | 200K tokens | High-quality responses with large context |
| `amazon.titan-text-express-v1` | Titan Text Express | 8K tokens | Cost-effective Amazon model |
| `meta.llama3-70b-instruct-v1:0` | Llama 3 70B | 8K tokens | Open model with strong performance |

### Example Code for Claude Models

```python
def generate_response(query, context_chunks):
    model_id = "anthropic.claude-3-5-sonnet-20240620-v1:0"
    
    # Combine context chunks
    context = "\n\n".join([chunk['text'] for chunk in context_chunks])
    
    # Create prompt
    prompt = f"""
    Human: I need you to answer a question based on the following context information.
    Only use information from the provided context to answer the question.
    If you don't know the answer or can't find it in the context, just say so.
    Be concise and to the point.

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
```

### Example Code for Titan Models

```python
def generate_response(query, context_chunks):
    model_id = "amazon.titan-text-express-v1"
    
    # Combine context chunks
    context = "\n\n".join([chunk['text'] for chunk in context_chunks])
    
    # Create prompt
    prompt = f"""
    Answer the following question based on the provided context.
    Only use information from the context to answer the question.
    If you don't know the answer or can't find it in the context, just say so.
    
    Context:
    {context}
    
    Question: {query}
    """
    
    body = json.dumps({
        "inputText": prompt,
        "textGenerationConfig": {
            "maxTokenCount": 500,
            "temperature": 0.7,
            "topP": 0.9
        }
    })
    
    response = bedrock_runtime.invoke_model(
        modelId=model_id,
        body=body
    )
    
    response_body = json.loads(response['body'].read())
    return response_body['results'][0]['outputText']
```

## Model Performance Considerations

When selecting models, consider these performance factors:

1. **Quality vs. Speed**:
   - Larger models (Claude 3.5 Sonnet, Llama 3 70B) generally produce higher quality responses
   - Smaller models (Claude 3 Haiku, Titan Text Express) are faster and more cost-effective

2. **Context Window Size**:
   - Larger context windows allow more document chunks to be included
   - Claude 3.5 Sonnet has a 200K token context window, making it ideal for processing large documents

3. **Embedding Quality**:
   - Higher quality embeddings improve search relevance
   - Titan Embeddings V2 and Cohere Embed models provide good quality for most use cases

4. **Response Format Control**:
   - Claude models offer better control over response formatting
   - Titan models may require more explicit prompting for consistent formatting

## Cost Considerations

Model costs vary significantly:

1. **Embedding Models**:
   - Titan Embed: $0.0001 per 1K tokens
   - Cohere Embed: $0.0001 per 1K tokens

2. **Text Generation Models** (Input/Output pricing):
   - Claude 3 Haiku: $0.00025/$0.00125 per 1K tokens
   - Claude 3 Sonnet: $0.003/$0.015 per 1K tokens
   - Claude 3.5 Sonnet: $0.005/$0.025 per 1K tokens
   - Titan Text Express: $0.0003/$0.0004 per 1K tokens
   - Llama 3 70B: $0.00195/$0.00195 per 1K tokens

For cost optimization:
- Use Claude 3 Haiku for most queries
- Reserve Claude 3.5 Sonnet for complex queries requiring deep understanding
- Consider Titan Text Express for high-volume, simple queries

## Region Availability

Not all models are available in all AWS regions. Check availability in your region:

```bash
aws bedrock list-foundation-models --region ap-south-1
```

Key regions with good model availability:
- `us-east-1` (N. Virginia): All models
- `us-west-2` (Oregon): All models
- `ap-southeast-1` (Singapore): Most models
- `ap-south-1` (Mumbai): Limited selection
- `eu-west-1` (Ireland): Most models

If a model isn't available in your region, consider:
1. Using a different model that is available
2. Deploying your Lambda functions in a region where the model is available
3. Using cross-region API calls (adds latency)
