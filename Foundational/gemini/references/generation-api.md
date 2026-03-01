# Gemini Generation API Reference

Complete reference for `generateContent` and `streamGenerateContent` endpoints.

## Endpoints

### generateContent (Unary)

```
POST /v1beta/models/{model}:generateContent
```

Returns the complete response in one JSON object.

### streamGenerateContent (Streaming)

```
POST /v1beta/models/{model}:streamGenerateContent?alt=sse
```

Returns server-sent events (SSE), each containing a partial response chunk.

## Request Body

```json
{
  "contents": [...],
  "systemInstruction": {...},
  "generationConfig": {...},
  "safetySettings": [...],
  "tools": [...],
  "toolConfig": {...},
  "cachedContent": "cachedContents/..."
}
```

### contents (required)

Array of `Content` objects representing the conversation:

```json
{
  "role": "user" | "model" | "function",
  "parts": [Part, ...]
}
```

### Part Types

| Part Type | Schema | Use Case |
|-----------|--------|----------|
| Text | `{"text": "..."}` | Plain text input |
| Inline data | `{"inlineData": {"mimeType": "...", "data": "base64..."}}` | Images, audio, small files (<20MB) |
| File data | `{"fileData": {"mimeType": "...", "fileUri": "..."}}` | Uploaded files (Files API) |
| Function call | `{"functionCall": {"name": "...", "args": {...}}}` | Model requesting function execution |
| Function response | `{"functionResponse": {"name": "...", "response": {...}}}` | Result from function execution |
| Executable code | `{"executableCode": {"language": "PYTHON", "code": "..."}}` | Model-generated code (code execution) |
| Code result | `{"codeExecutionResult": {"output": "...", "outcome": "OUTCOME_OK"}}` | Code execution result |

### systemInstruction

```json
{
  "parts": [{"text": "You are a helpful assistant."}]
}
```

System instructions set the model's behavior. Supported on all Gemini 1.5+ models.

### generationConfig

| Parameter | Type | Range | Default | Description |
|-----------|------|-------|---------|-------------|
| `temperature` | float | 0.0–2.0 | 1.0 | Randomness. Lower = more deterministic |
| `topP` | float | 0.0–1.0 | model-dependent | Nucleus sampling threshold |
| `topK` | int | 1–∞ | model-dependent | Top-K sampling |
| `maxOutputTokens` | int | 1–model max | model-dependent | Max tokens in response |
| `candidateCount` | int | 1 | 1 | Number of response candidates |
| `stopSequences` | string[] | max 5 | — | Stop generation at these strings |
| `presencePenalty` | float | -2.0–2.0 | 0 | Penalize tokens already present |
| `frequencyPenalty` | float | -2.0–2.0 | 0 | Penalize frequent tokens |
| `responseMimeType` | string | — | `text/plain` | `application/json` for JSON mode, `text/x.enum` for enum |
| `responseSchema` | object | — | — | JSON Schema constraining output |
| `routingConfig` | object | — | — | Model routing for Gemini 2.0 Flash Thinking |
| `thinkingConfig` | object | — | — | Control reasoning behavior |
| `seed` | int | — | — | Seed for reproducibility (best effort) |
| `responseLogprobs` | bool | — | false | Return log probabilities |
| `logprobs` | int | 0–20 | — | Number of log probs per token |
| `audioTimestamp` | bool | — | false | Include audio timestamps |
| `mediaResolution` | string | — | — | `MEDIA_RESOLUTION_LOW` / `MEDIA_RESOLUTION_MEDIUM` / `MEDIA_RESOLUTION_HIGH` |

### thinkingConfig

For Gemini 2.5 models (budget-based):

```json
{"thinkingConfig": {"thinkingBudget": 8192}}
```

- `thinkingBudget: -1` — dynamic (model decides)
- `thinkingBudget: 0` — disable thinking (Flash/Flash-Lite only)
- Range: 128–32768 (Pro), 0–24576 (Flash), 0–24576 (Flash-Lite)

For Gemini 3 models (level-based):

```json
{"thinkingConfig": {"thinkingLevel": "medium"}}
```

- Values: `minimal`, `low`, `medium`, `high`
- Not all levels available on all models (see SKILL.md table)

### safetySettings

Array of category + threshold pairs:

```json
[
  {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_ONLY_HIGH"},
  {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
  {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"},
  {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_LOW_AND_ABOVE"},
  {"category": "HARM_CATEGORY_CIVIC_INTEGRITY", "threshold": "BLOCK_NONE"}
]
```

Thresholds: `BLOCK_NONE` < `BLOCK_ONLY_HIGH` < `BLOCK_MEDIUM_AND_ABOVE` < `BLOCK_LOW_AND_ABOVE`.

## Response Schema

### generateContent response

```json
{
  "candidates": [{
    "content": {
      "role": "model",
      "parts": [{"text": "..."}]
    },
    "finishReason": "STOP",
    "safetyRatings": [...],
    "citationMetadata": {...}
  }],
  "usageMetadata": {
    "promptTokenCount": 10,
    "candidatesTokenCount": 50,
    "totalTokenCount": 60,
    "thoughtsTokenCount": 200
  },
  "modelVersion": "gemini-2.5-flash-001"
}
```

### Finish Reasons

| Reason | Meaning |
|--------|---------|
| `STOP` | Natural completion |
| `MAX_TOKENS` | Hit maxOutputTokens limit |
| `SAFETY` | Blocked by safety filter |
| `RECITATION` | Blocked due to recitation concerns |
| `OTHER` | Other reason |
| `BLOCKLIST` | Blocked by terminology blocklist |
| `PROHIBITED_CONTENT` | Potentially prohibited content |
| `SPII` | Contains sensitive PII |
| `MALFORMED_FUNCTION_CALL` | Invalid function call |

### Streaming response

Each SSE event is a partial `GenerateContentResponse`. Parts accumulate across chunks. The final chunk contains `usageMetadata`.

## Multimodal Input Patterns

### Single image

```json
{"contents": [{"parts": [
  {"text": "Describe this image"},
  {"inlineData": {"mimeType": "image/jpeg", "data": "base64..."}}
]}]}
```

### Multiple images

```json
{"contents": [{"parts": [
  {"text": "Compare these two images"},
  {"inlineData": {"mimeType": "image/jpeg", "data": "base64_1"}},
  {"inlineData": {"mimeType": "image/jpeg", "data": "base64_2"}}
]}]}
```

### Image from URL (via fileData after upload)

```json
{"contents": [{"parts": [
  {"text": "Analyze this"},
  {"fileData": {"mimeType": "image/png", "fileUri": "https://generativelanguage.googleapis.com/v1beta/files/abc123"}}
]}]}
```

### Audio analysis

```json
{"contents": [{"parts": [
  {"text": "Transcribe this audio"},
  {"inlineData": {"mimeType": "audio/mp3", "data": "base64..."}}
]}]}
```

Supported audio: MP3, WAV, AIFF, AAC, OGG, FLAC (up to 9.5 hours inline).

### Video analysis

For video, upload via the Files API first (videos are typically too large for inline):

```json
{"contents": [{"parts": [
  {"fileData": {"mimeType": "video/mp4", "fileUri": "https://generativelanguage.googleapis.com/v1beta/files/abc123"}},
  {"text": "Summarize this video"}
]}]}
```

Supported video: MP4, MPEG, MOV, AVI, FLV, MKV, WebM, WMV, 3GPP.

### PDF / Document analysis

```json
{"contents": [{"parts": [
  {"inlineData": {"mimeType": "application/pdf", "data": "base64..."}},
  {"text": "Summarize the key points"}
]}]}
```

Up to 1000 pages per PDF. Supports text, images, and tables within PDFs.

## Structured Output Details

### JSON mode (free-form)

Set `responseMimeType: "application/json"` without a schema. Model returns valid JSON.

### JSON with schema

Set both `responseMimeType: "application/json"` and `responseSchema`. Model output strictly matches the schema.

Supported schema features:
- `type`: string, number, integer, boolean, array, object
- `properties`, `required` for objects
- `items` for arrays
- `enum` for constrained values
- `description` for guiding the model
- `nullable` for optional fields
- `anyOf` for union types

### Enum mode

Set `responseMimeType: "text/x.enum"` with `responseSchema.enum` for classification:

```json
{
  "generationConfig": {
    "responseMimeType": "text/x.enum",
    "responseSchema": {
      "type": "string",
      "enum": ["positive", "negative", "neutral"]
    }
  }
}
```
