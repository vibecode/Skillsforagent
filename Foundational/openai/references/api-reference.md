# OpenAI API Reference

Complete endpoint reference for the OpenAI API. Consult this when you need full parameter details beyond what's in SKILL.md.

## Table of Contents

1. [Chat Completions](#chat-completions)
2. [Responses API](#responses-api)
3. [Image Generation](#image-generation)
4. [Image Editing](#image-editing)
5. [Audio — Speech](#audio--speech)
6. [Audio — Transcription](#audio--transcription)
7. [Audio — Translation](#audio--translation)
8. [Embeddings](#embeddings)
9. [Moderations](#moderations)
10. [Models](#models)
11. [Files](#files)

---

## Chat Completions

`POST /v1/chat/completions`

### Request Body

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `model` | string | ✅ | — | Model ID (see models table in SKILL.md) |
| `messages` | array | ✅ | — | Array of message objects |
| `temperature` | float | — | 1.0 | Sampling temperature (0–2). Lower = more focused. |
| `top_p` | float | — | 1.0 | Nucleus sampling. Don't combine with temperature. |
| `n` | int | — | 1 | How many completions to generate |
| `stream` | bool | — | false | SSE streaming |
| `stream_options` | object | — | null | `{"include_usage": true}` for usage in stream |
| `stop` | string/array | — | null | Up to 4 stop sequences |
| `max_tokens` | int | — | model max | Max tokens in response (legacy) |
| `max_completion_tokens` | int | — | — | Preferred for newer models; includes reasoning tokens for o-series |
| `presence_penalty` | float | — | 0 | -2.0 to 2.0. Positive penalizes new topics. |
| `frequency_penalty` | float | — | 0 | -2.0 to 2.0. Positive penalizes repetition. |
| `logit_bias` | map | — | null | Map token IDs to bias (-100 to 100) |
| `logprobs` | bool | — | false | Return log probabilities |
| `top_logprobs` | int | — | — | 0–20 logprobs per token position |
| `response_format` | object | — | `{"type":"text"}` | `json_object`, `json_schema`, or `text` |
| `seed` | int | — | — | For reproducible outputs (best effort) |
| `tools` | array | — | — | Function definitions for tool calling |
| `tool_choice` | string/object | — | `"auto"` | `"auto"`, `"none"`, `"required"`, or specific function |
| `parallel_tool_calls` | bool | — | true | Allow multiple simultaneous tool calls |
| `user` | string | — | — | Unique user identifier for abuse detection |
| `reasoning_effort` | string | — | — | For reasoning models: `low`, `medium`, `high` |
| `store` | bool | — | — | Store the completion for later retrieval |
| `metadata` | map | — | — | Key-value pairs for filtering stored completions |

### Message Roles

| Role | Purpose |
|------|---------|
| `system` | Sets behavior/persona. Not supported by o-series (use `developer`). |
| `developer` | Like system but for o-series reasoning models |
| `user` | User input. Content can be string or array (for images). |
| `assistant` | Previous model responses (for multi-turn) |
| `tool` | Tool/function results. Must include `tool_call_id`. |

### Vision Content Array

When using vision, the `content` field is an array:

```json
[
  {"type": "text", "text": "Describe this image"},
  {"type": "image_url", "image_url": {"url": "https://...", "detail": "auto"}}
]
```

- `detail`: `auto` (let model decide), `low` (512px, fixed 85 tokens), `high` (up to 2048px, more tokens)
- Supports URLs and base64 data URIs: `data:image/jpeg;base64,...`
- Multiple images allowed in one message

### Structured Output — json_schema

```json
{
  "response_format": {
    "type": "json_schema",
    "json_schema": {
      "name": "my_schema",
      "strict": true,
      "schema": {
        "type": "object",
        "properties": {...},
        "required": [...],
        "additionalProperties": false
      }
    }
  }
}
```

Rules for `strict: true`:
- All fields must be `required`
- `additionalProperties: false` at every object level
- No `default` values
- Supported types: `string`, `number`, `integer`, `boolean`, `array`, `object`, `null`
- Use `anyOf` for optional fields: `{"anyOf": [{"type": "string"}, {"type": "null"}]}`
- Max nesting depth: 5 levels

### Function Calling Flow

1. Send request with `tools` array
2. Model returns `finish_reason: "tool_calls"` with `tool_calls` array
3. Execute the functions
4. Send results back as `tool` role messages with matching `tool_call_id`
5. Model generates final response

Tool call response format:
```json
{
  "choices": [{
    "message": {
      "role": "assistant",
      "tool_calls": [{
        "id": "call_abc123",
        "type": "function",
        "function": {
          "name": "get_weather",
          "arguments": "{\"location\": \"London\"}"
        }
      }]
    },
    "finish_reason": "tool_calls"
  }]
}
```

### Response Object

```json
{
  "id": "chatcmpl-...",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "gpt-4o-2025-...",
  "choices": [{
    "index": 0,
    "message": {"role": "assistant", "content": "..."},
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 20,
    "total_tokens": 30,
    "completion_tokens_details": {"reasoning_tokens": 0}
  }
}
```

`finish_reason` values: `stop`, `length`, `tool_calls`, `content_filter`

---

## Responses API

`POST /v1/responses`

The Responses API manages conversation state server-side and provides built-in tools.

### Request Body

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `model` | string | ✅ | — | Model ID |
| `input` | string/array | ✅ | — | Text string or array of input items |
| `instructions` | string | — | — | System-level instructions |
| `tools` | array | — | — | Built-in + custom tools |
| `tool_choice` | string/object | — | `"auto"` | Tool selection strategy |
| `previous_response_id` | string | — | — | Chain multi-turn conversations |
| `text` | object | — | — | Text output config (format, etc.) |
| `temperature` | float | — | 1.0 | Sampling temperature |
| `top_p` | float | — | 1.0 | Nucleus sampling |
| `max_output_tokens` | int | — | — | Max tokens |
| `reasoning` | object | — | — | `{"effort": "medium", "summary": "auto"}` |
| `store` | bool | — | true | Store response (default true, unlike chat completions) |
| `metadata` | map | — | — | Key-value metadata |
| `stream` | bool | — | false | SSE streaming |

### Structured Output in Responses API

```json
{
  "text": {
    "format": {
      "type": "json_schema",
      "name": "my_schema",
      "strict": true,
      "schema": {...}
    }
  }
}
```

### Built-in Tools

**Web Search:**
```json
{"type": "web_search_preview"}
{"type": "web_search_preview", "search_context_size": "medium"}
```

**File Search:**
```json
{"type": "file_search", "vector_store_ids": ["vs_abc123"]}
```

**Code Interpreter:**
```json
{"type": "code_interpreter"}
```

**Computer Use (preview):**
```json
{"type": "computer_use_preview", "display_width": 1024, "display_height": 768, "environment": "browser"}
```

### Multi-Turn with previous_response_id

```bash
# Turn 1
RESP=$(curl -s -X POST "${BASE}/responses" ... -d '{"model":"gpt-4o","input":"Hi"}')
RESP_ID=$(echo "$RESP" | jq -r '.id')

# Turn 2
curl -X POST "${BASE}/responses" ... \
  -d "{\"model\":\"gpt-4o\",\"input\":\"Follow up question\",\"previous_response_id\":\"$RESP_ID\"}"
```

### Retrieve a Response

`GET /v1/responses/{response_id}`

### Delete a Response

`DELETE /v1/responses/{response_id}`

### List Input Items

`GET /v1/responses/{response_id}/input_items`

---

## Image Generation

`POST /v1/images/generations`

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `model` | string | — | `dall-e-3` | `gpt-image-1.5`, `gpt-image-1`, `gpt-image-1-mini`, `dall-e-3`, `dall-e-2` |
| `prompt` | string | ✅ | — | Description of desired image (max 32000 chars for GPT image, 4000 for DALL-E 3) |
| `n` | int | — | 1 | 1–4 for GPT image; 1 for DALL-E 3 |
| `size` | string | — | `1024x1024` | See size options per model in SKILL.md |
| `quality` | string | — | `auto` | GPT image: `auto`/`low`/`medium`/`high`; DALL-E 3: `standard`/`hd` |
| `response_format` | string | — | model-dependent | `b64_json` or `url` |
| `output_format` | string | — | `png` | GPT image only: `png`, `jpeg`, `webp` |
| `output_compression` | int | — | — | 0–100, JPEG/WebP compression |
| `background` | string | — | `auto` | GPT image only: `auto`, `transparent`, `opaque` |
| `style` | string | — | `vivid` | DALL-E 3 only: `vivid` or `natural` |
| `user` | string | — | — | User identifier |

### Response

```json
{
  "created": 1234567890,
  "data": [{
    "b64_json": "iVBOR...",
    "revised_prompt": "A detailed description..."
  }]
}
```

For `url` format: `"url": "https://..."` (expires after 1 hour for DALL-E).

---

## Image Editing

`POST /v1/images/edits`

Multipart form data.

| Parameter | Type | Required | Notes |
|-----------|------|----------|-------|
| `model` | string | — | `gpt-image-1.5`, `gpt-image-1`, `gpt-image-1-mini`, `dall-e-2` |
| `prompt` | string | ✅ | Edit instruction |
| `image[]` | file | ✅ | Image file(s). GPT image: up to 16. Must be PNG for DALL-E 2. |
| `mask` | file | — | Mask indicating edit area (DALL-E 2 only; transparent = edit area) |
| `n` | int | — | 1–4 for GPT image |
| `size` | string | — | Same options as generation |
| `quality` | string | — | Same options as generation |

---

## Audio — Speech

`POST /v1/audio/speech`

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `model` | string | ✅ | — | `gpt-4o-mini-tts`, `tts-1`, `tts-1-hd` |
| `input` | string | ✅ | — | Text to speak. Max 4096 chars (tts-1/hd), 2000 tokens (gpt-4o-mini-tts) |
| `voice` | string | ✅ | — | `alloy`, `ash`, `ballad`, `coral`, `echo`, `fable`, `nova`, `onyx`, `sage`, `shimmer`, `verse` |
| `instructions` | string | — | — | Voice direction (gpt-4o-mini-tts only). Natural language. |
| `response_format` | string | — | `mp3` | `mp3`, `opus`, `aac`, `flac`, `wav`, `pcm` |
| `speed` | float | — | 1.0 | 0.25–4.0 (tts-1/tts-1-hd only, not gpt-4o-mini-tts) |

Returns raw audio bytes. Save with `--output file.mp3`.

---

## Audio — Transcription

`POST /v1/audio/transcriptions`

Multipart form data.

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `file` | file | ✅ | — | Audio file (mp3, mp4, mpeg, mpga, m4a, wav, webm). Max 25MB. |
| `model` | string | ✅ | — | `gpt-4o-transcribe`, `gpt-4o-mini-transcribe`, `gpt-4o-transcribe-diarize`, `whisper-1` |
| `language` | string | — | — | ISO-639-1 code |
| `prompt` | string | — | — | Context/vocabulary hints |
| `response_format` | string | — | `json` | `json`, `text`, `srt`, `verbose_json`, `vtt` |
| `temperature` | float | — | 0 | 0–1 |
| `timestamp_granularities` | array | — | `["segment"]` | `["word"]`, `["segment"]`, or both. Requires `verbose_json`. |

### Diarization (gpt-4o-transcribe-diarize)

Returns speaker-labeled segments:
```json
{
  "text": "Hello, how are you?",
  "words": [{"word": "Hello", "start": 0.0, "end": 0.5, "speaker": "speaker_0"}]
}
```

---

## Audio — Translation

`POST /v1/audio/translations`

Translates audio to English text. Same parameters as transcription except no `language` param. Only supports `whisper-1` model.

---

## Embeddings

`POST /v1/embeddings`

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `model` | string | ✅ | — | `text-embedding-3-small`, `text-embedding-3-large` |
| `input` | string/array | ✅ | — | Text or array of texts. Max 8192 tokens per input. |
| `dimensions` | int | — | model default | Truncate embedding to this size |
| `encoding_format` | string | — | `float` | `float` or `base64` |
| `user` | string | — | — | User identifier |

### Response

```json
{
  "object": "list",
  "data": [{
    "object": "embedding",
    "embedding": [0.0023, -0.0094, ...],
    "index": 0
  }],
  "model": "text-embedding-3-small",
  "usage": {"prompt_tokens": 8, "total_tokens": 8}
}
```

---

## Moderations

`POST /v1/moderations`

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `model` | string | — | `omni-moderation-latest` | `omni-moderation-latest`, `text-moderation-latest` |
| `input` | string/array | ✅ | — | Text string(s) or array of text/image objects |

For image moderation (omni-moderation only):
```json
{
  "input": [
    {"type": "text", "text": "Check this"},
    {"type": "image_url", "image_url": {"url": "https://..."}}
  ]
}
```

### Response Categories

`harassment`, `harassment/threatening`, `hate`, `hate/threatening`, `illicit`, `illicit/violent`, `self-harm`, `self-harm/intent`, `self-harm/instructions`, `sexual`, `sexual/minors`, `violence`, `violence/graphic`

Each has a boolean `flagged` and float `score` (0–1).

---

## Models

### List Models

`GET /v1/models`

### Retrieve Model

`GET /v1/models/{model_id}`

---

## Files

### Upload File

`POST /v1/files`

```bash
curl -X POST "${BASE}/files" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -F "purpose=assistants" \
  -F "file=@document.pdf"
```

`purpose`: `assistants`, `batch`, `fine-tune`, `vision`

### List Files

`GET /v1/files`

### Retrieve File

`GET /v1/files/{file_id}`

### Delete File

`DELETE /v1/files/{file_id}`

### Retrieve File Content

`GET /v1/files/{file_id}/content`
