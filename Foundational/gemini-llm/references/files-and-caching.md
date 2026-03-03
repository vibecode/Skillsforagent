# Gemini Files API & Context Caching Reference

Complete reference for file uploads, management, and context caching.

## Files API

Upload and manage files for use in Gemini prompts. Required for:
- Files larger than 20MB (inline data limit)
- Video files (recommended to always upload)
- Reusing the same file across multiple requests

### Upload a File (Resumable)

**Step 1: Initiate upload**

```bash
UPLOAD_URL=$(curl -s -D - \
  "https://generativelanguage.googleapis.com.cloudproxy.vibecodeapp.com/upload/v1beta/files" \
  -H "x-goog-api-key: ${GOOGLE_API_KEY}" \
  -H "X-Goog-Upload-Protocol: resumable" \
  -H "X-Goog-Upload-Command: start" \
  -H "X-Goog-Upload-Header-Content-Length: BYTE_SIZE" \
  -H "X-Goog-Upload-Header-Content-Type: MIME_TYPE" \
  -H "Content-Type: application/json" \
  -d '{"file": {"display_name": "NAME"}}' \
  2>/dev/null | grep -i "x-goog-upload-url" | cut -d' ' -f2 | tr -d '\r')
```

**Step 2: Upload bytes**

```bash
curl -s "${UPLOAD_URL}" \
  -H "X-Goog-Upload-Offset: 0" \
  -H "X-Goog-Upload-Command: upload, finalize" \
  --data-binary @file.ext
```

Response:

```json
{
  "file": {
    "name": "files/abc123def",
    "displayName": "my-file",
    "mimeType": "video/mp4",
    "sizeBytes": "12345678",
    "createTime": "2024-01-01T00:00:00Z",
    "updateTime": "2024-01-01T00:00:00Z",
    "expirationTime": "2024-01-03T00:00:00Z",
    "sha256Hash": "...",
    "uri": "https://generativelanguage.googleapis.com/v1beta/files/abc123def",
    "state": "ACTIVE"
  }
}
```

### File States

| State | Meaning |
|-------|---------|
| `PROCESSING` | File is being processed (wait before using) |
| `ACTIVE` | File is ready to use in prompts |
| `FAILED` | Processing failed |

Poll the file's status until `ACTIVE` before using it:

```bash
curl -s "${BASE}/files/FILE_ID" -H "x-goog-api-key: ${GOOGLE_API_KEY}" | jq '.state'
```

### List Files

```bash
curl -s "${BASE}/files" \
  -H "x-goog-api-key: ${GOOGLE_API_KEY}" \
  | jq '.files[]'
```

Optional parameters: `pageSize` (max 100), `pageToken`.

### Get File Metadata

```bash
curl -s "${BASE}/files/FILE_ID" -H "x-goog-api-key: ${GOOGLE_API_KEY}"
```

### Delete a File

```bash
curl -s -X DELETE "${BASE}/files/FILE_ID" -H "x-goog-api-key: ${GOOGLE_API_KEY}"
```

### File Expiration

Files auto-expire after **48 hours**. You cannot extend the expiration. Re-upload if needed.

### Supported MIME Types

**Images:** image/png, image/jpeg, image/gif, image/webp, image/heic, image/heif

**Audio:** audio/wav, audio/mp3, audio/aiff, audio/aac, audio/ogg, audio/flac

**Video:** video/mp4, video/mpeg, video/mov, video/avi, video/x-flv, video/mpg, video/webm, video/wmv, video/3gpp

**Documents:** application/pdf, text/plain, text/html, text/css, text/javascript, text/x-python, text/csv, text/xml, text/rtf, application/x-javascript, application/x-python

**Structured data:** application/json, application/xml

### Size Limits

| Method | Max Size |
|--------|----------|
| Inline data (base64 in request) | 20 MB |
| Files API upload | 2 GB |

### Using Uploaded Files in Prompts

Reference uploaded files with `fileData`:

```json
{
  "contents": [{
    "parts": [
      {"fileData": {"mimeType": "video/mp4", "fileUri": "URI_FROM_UPLOAD"}},
      {"text": "Describe what happens in this video"}
    ]
  }]
}
```

## Context Caching

Cache large prompts to reduce cost and latency on repeated queries. Cached tokens are charged at 75% less than normal input tokens.

### Create a Cache

```bash
curl -s "${BASE}/cachedContents" \
  -H "x-goog-api-key: ${GOOGLE_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "models/MODEL_NAME",
    "contents": [{
      "parts": [{"text": "Very long document..."}],
      "role": "user"
    }],
    "systemInstruction": {
      "parts": [{"text": "System prompt"}]
    },
    "ttl": "3600s",
    "displayName": "my-cache"
  }'
```

Response includes `name` (e.g., `cachedContents/abc123`) used to reference the cache.

### Cache Requirements

| Model | Minimum Tokens |
|-------|---------------|
| Gemini 2.5 Flash / Flash-Lite | 1,024 |
| Gemini 2.5 Pro | 4,096 |
| Gemini 1.5 Flash | 32,768 |
| Gemini 1.5 Pro | 32,768 |

### What Can Be Cached

- Text content
- Uploaded files (via fileData)
- System instructions
- Function declarations (tools)
- Combination of the above

### Using a Cache

Reference the cache by name in `generateContent`:

```json
{
  "cachedContent": "cachedContents/abc123",
  "contents": [{
    "parts": [{"text": "Question about the cached content"}],
    "role": "user"
  }]
}
```

**Important:** Do not repeat `systemInstruction`, `tools`, or cached content in the request. They're already in the cache. Only send new `contents`.

### TTL and Expiration

- `ttl`: Time-to-live in seconds (e.g., `"3600s"` for 1 hour)
- `expireTime`: Absolute timestamp (ISO 8601)
- Default TTL: 1 hour
- Minimum TTL: 0 (expires immediately — useful for one-shot)
- Maximum TTL: no hard limit, but charged per hour of storage

### Update Cache TTL

```bash
curl -s -X PATCH "${BASE}/cachedContents/CACHE_NAME" \
  -H "x-goog-api-key: ${GOOGLE_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"ttl": "7200s"}'
```

### List Caches

```bash
curl -s "${BASE}/cachedContents" -H "x-goog-api-key: ${GOOGLE_API_KEY}"
```

### Delete a Cache

```bash
curl -s -X DELETE "${BASE}/cachedContents/CACHE_NAME" -H "x-goog-api-key: ${GOOGLE_API_KEY}"
```

## Batch Embeddings

Embed multiple texts in one request:

```bash
curl -s "${BASE}/models/gemini-embedding-001:batchEmbedContents" \
  -H "x-goog-api-key: ${GOOGLE_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "requests": [
      {
        "model": "models/gemini-embedding-001",
        "content": {"parts": [{"text": "First text"}]},
        "taskType": "RETRIEVAL_DOCUMENT"
      },
      {
        "model": "models/gemini-embedding-001",
        "content": {"parts": [{"text": "Second text"}]},
        "taskType": "RETRIEVAL_DOCUMENT"
      }
    ]
  }'
```

Response:

```json
{
  "embeddings": [
    {"values": [0.123, -0.456, ...]},
    {"values": [0.789, -0.012, ...]}
  ]
}
```

### Embedding Configuration

| Parameter | Type | Description |
|-----------|------|-------------|
| `taskType` | string | One of the task types (see SKILL.md) |
| `outputDimensionality` | int | Reduce dimensions (default 3072, can set 768, 256, etc.) |
| `title` | string | Optional title for RETRIEVAL_DOCUMENT task type |

Lower dimensionality = smaller vectors, slightly less accuracy, faster similarity search.
