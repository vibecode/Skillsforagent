---
name: openai
description: >
  Foundational skill for the OpenAI API — chat completions, reasoning models, image generation,
  vision, embeddings, text-to-speech, speech-to-text, structured outputs, function calling, and
  moderation. Use this skill when: (1) generating text with GPT models (GPT-4o, GPT-4.1, GPT-5,
  GPT-5.2), (2) using reasoning models (o3, o4-mini, o1), (3) generating or editing images
  (gpt-image-1, gpt-image-1.5, DALL-E 3), (4) analyzing images with vision (GPT-4o, GPT-4.1),
  (5) generating embeddings (text-embedding-3-small/large), (6) text-to-speech with
  gpt-4o-mini-tts, (7) speech-to-text transcription (gpt-4o-transcribe, whisper-1), (8) using
  structured outputs or JSON mode, (9) function calling / tool use, (10) content moderation
  (omni-moderation), (11) using the Responses API with built-in tools (web search, file search,
  code interpreter). Includes a wrapper script for common operations. This is the base OpenAI
  skill — specialized skills may reference it for specific workflows.
metadata: {"openclaw": {"emoji": "🤖", "requires": {"env": ["OPENAI_API_KEY"]}, "primaryEnv": "OPENAI_API_KEY"}}
---

# OpenAI API

Access GPT models, reasoning, image generation, audio, embeddings, and more via HTTP.

## Authentication

```
Base URL: https://api.openai.com.cloudproxy.vibecodeapp.com/v1
Header:   Authorization: Bearer $OPENAI_API_KEY
```

The cloud proxy handles credentials. Use `$OPENAI_API_KEY` as-is.

## Wrapper Script

The fastest way to use this API. Handles auth, JSON construction, binary responses, streaming, and error handling.

```bash
SCRIPT="/path/to/openai/scripts/openai.sh"
```

### Quick Reference

```bash
# Chat completions
bash $SCRIPT chat --text "Explain quantum computing" --model gpt-4.1
bash $SCRIPT chat --text "What's in this image?" --image photo.jpg --model gpt-4o
bash $SCRIPT chat --system "You are a pirate" --text "Tell me about the sea" --model gpt-4o
bash $SCRIPT chat --file prompt.txt --model gpt-4.1 --max-tokens 2000

# Streaming
bash $SCRIPT stream --text "Write a long story" --model gpt-4o

# Reasoning models
bash $SCRIPT chat --text "Solve this math problem: ..." --model o3 --reasoning medium
bash $SCRIPT chat --text "Debug this code: ..." --model o4-mini --reasoning high

# Structured output (JSON schema)
bash $SCRIPT chat --text "Extract name and age" --model gpt-4o \
  --schema '{"type":"object","properties":{"name":{"type":"string"},"age":{"type":"integer"}},"required":["name","age"],"additionalProperties":false}'

# Image generation
bash $SCRIPT image-gen --prompt "A cat in a spacesuit" --out cat.png
bash $SCRIPT image-gen --prompt "Logo design" --model gpt-image-1.5 --size 1024x1024 --quality high --out logo.png

# Image editing
bash $SCRIPT image-edit --prompt "Add sunglasses" --image face.png --out edited.png

# Text-to-speech
bash $SCRIPT tts --text "Hello world" --voice alloy --out hello.mp3
bash $SCRIPT tts --text "Dramatic reading" --voice onyx --instructions "Speak slowly and dramatically" --out dramatic.mp3

# Speech-to-text
bash $SCRIPT stt --audio recording.mp3 --out transcript.json
bash $SCRIPT stt --audio meeting.mp3 --model gpt-4o-transcribe --out transcript.json

# Embeddings
bash $SCRIPT embed --text "Hello world" --model text-embedding-3-small
bash $SCRIPT embed --file texts.jsonl --model text-embedding-3-large --dimensions 1024

# Moderation
bash $SCRIPT moderate --text "Some content to check"

# List models
bash $SCRIPT models
```

### Script Flags Reference

| Command | Required Flags | Optional Flags |
|---------|---------------|----------------|
| `chat` | `--text` or `--file` | `--model`, `--system`, `--image`, `--max-tokens`, `--temp`, `--top-p`, `--reasoning`, `--schema`, `--schema-name`, `--json`, `--tools` (JSON file), `--seed`, `--n` |
| `stream` | `--text` or `--file` | Same as `chat` (streams output) |
| `image-gen` | `--prompt`, `--out` | `--model`, `--size`, `--quality`, `--n`, `--background`, `--output-format` |
| `image-edit` | `--prompt`, `--image`, `--out` | `--model`, `--mask`, `--size`, `--quality`, `--n` |
| `tts` | `--text` or `--file`, `--out` | `--model`, `--voice`, `--instructions`, `--speed`, `--format` |
| `stt` | `--audio`, `--out` | `--model`, `--language`, `--prompt`, `--format`, `--timestamps` |
| `embed` | `--text` or `--file` | `--model`, `--dimensions`, `--encoding-format` |
| `moderate` | `--text` | `--model` |
| `models` | — | — |

## Model Quick Reference

Models change frequently. Use `bash $SCRIPT models` or the [Models API](#list-models) for the live list. This is a convenience starting point — **not exhaustive**.

### Chat / Reasoning

| Model | Type | Best For |
|-------|------|----------|
| `gpt-5.2` | Flagship | Latest, best overall (coding, reasoning, agentic) |
| `gpt-5` | Flagship | Coding, reasoning, agentic tasks |
| `gpt-5-mini` | Small | Cost-efficient GPT-5 |
| `gpt-4.1` | Smart | Strong non-reasoning model |
| `gpt-4.1-mini` | Small | Faster, cheaper GPT-4.1 |
| `gpt-4.1-nano` | Tiny | Fastest, cheapest GPT-4.1 |
| `gpt-4o` | Multimodal | Text + vision + audio |
| `gpt-4o-mini` | Small | Cost-efficient multimodal |
| `o3` | Reasoning | Complex reasoning tasks |
| `o4-mini` | Reasoning | Fast, cost-efficient reasoning |
| `o1` | Reasoning | Original reasoning model |
| `o1-pro` | Reasoning | More compute for harder problems |

### Image Generation

| Model | Notes |
|-------|-------|
| `gpt-image-1.5` | Latest, best quality + editing |
| `gpt-image-1` | Previous gen, still capable |
| `gpt-image-1-mini` | Smaller, cheaper image gen |
| `dall-e-3` | Legacy (deprecating May 2026) |

### Audio

| Model | Type |
|-------|------|
| `gpt-4o-mini-tts` | Text-to-speech (steerable via instructions) |
| `tts-1` | Optimized for speed |
| `tts-1-hd` | Optimized for quality |
| `gpt-4o-transcribe` | Speech-to-text (best quality) |
| `gpt-4o-mini-transcribe` | Speech-to-text (fast, cheap) |
| `gpt-4o-transcribe-diarize` | STT with speaker diarization |
| `whisper-1` | Open-source STT (legacy) |

### Embeddings

| Model | Dimensions | Notes |
|-------|-----------|-------|
| `text-embedding-3-large` | 3072 (adjustable) | Most capable |
| `text-embedding-3-small` | 1536 (adjustable) | Cost-efficient |

## Chat Completions

The workhorse endpoint. Supports text generation, vision, function calling, structured outputs, and streaming.

```bash
curl -X POST "${BASE}/chat/completions" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Hello!"}
    ]
  }'
```

### Vision (Image Input)

Pass images via URL or base64 in the `content` array:

```bash
curl -X POST "${BASE}/chat/completions" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o",
    "messages": [{
      "role": "user",
      "content": [
        {"type": "text", "text": "What is in this image?"},
        {"type": "image_url", "image_url": {"url": "https://example.com/photo.jpg", "detail": "auto"}}
      ]
    }]
  }'
```

`detail`: `auto` (default), `low` (512px, 85 tokens), or `high` (full resolution, more tokens).

For base64: `"url": "data:image/png;base64,iVBOR..."`.

### Structured Outputs (JSON Schema)

Force the model to output valid JSON matching your schema:

```bash
curl -X POST "${BASE}/chat/completions" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o",
    "messages": [{"role": "user", "content": "Extract the name and age from: John is 30"}],
    "response_format": {
      "type": "json_schema",
      "json_schema": {
        "name": "person",
        "strict": true,
        "schema": {
          "type": "object",
          "properties": {
            "name": {"type": "string"},
            "age": {"type": "integer"}
          },
          "required": ["name", "age"],
          "additionalProperties": false
        }
      }
    }
  }'
```

For simple JSON mode (no schema): `"response_format": {"type": "json_object"}`.

### Function Calling / Tools

Define tools the model can invoke:

```bash
curl -X POST "${BASE}/chat/completions" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o",
    "messages": [{"role": "user", "content": "What'\''s the weather in London?"}],
    "tools": [{
      "type": "function",
      "function": {
        "name": "get_weather",
        "description": "Get weather for a location",
        "parameters": {
          "type": "object",
          "properties": {
            "location": {"type": "string"}
          },
          "required": ["location"],
          "additionalProperties": false
        },
        "strict": true
      }
    }],
    "tool_choice": "auto"
  }'
```

When the model calls a tool, respond with:
```json
{"role": "tool", "tool_call_id": "call_abc123", "content": "{\"temp\": 15, \"unit\": \"celsius\"}"}
```

`tool_choice`: `"auto"` (default), `"none"`, `"required"`, or `{"type": "function", "function": {"name": "get_weather"}}`.

`parallel_tool_calls`: set to `false` to force one tool call at a time (GPT-4o supports parallel; o-series does not).

### Reasoning Models

o3, o4-mini, and GPT-5 with `reasoning_effort`:

```bash
curl -X POST "${BASE}/chat/completions" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "o3",
    "messages": [{"role": "user", "content": "Prove that sqrt(2) is irrational"}],
    "reasoning_effort": "high"
  }'
```

`reasoning_effort` values: `low`, `medium`, `high` (o-series). GPT-5/5.2 support `none`, `low`, `medium`, `high`, and `xhigh` (for GPT-5.2).

**Note:** Reasoning models don't support `temperature`, `top_p`, or `system` messages (use `developer` role instead for o-series).

### Streaming

Add `"stream": true` to any chat completion request. Responses arrive as SSE events:

```
data: {"id":"...","choices":[{"delta":{"content":"Hello"},"index":0}]}
data: {"id":"...","choices":[{"delta":{"content":" world"},"index":0}]}
data: [DONE]
```

With `"stream_options": {"include_usage": true}`, the final chunk includes token usage.

### Key Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `model` | string | required | Model ID |
| `messages` | array | required | Conversation messages |
| `temperature` | float | 1.0 | Randomness (0–2) |
| `top_p` | float | 1.0 | Nucleus sampling |
| `max_tokens` | int | model max | Max output tokens |
| `max_completion_tokens` | int | — | Preferred for newer models (includes reasoning tokens) |
| `n` | int | 1 | Number of completions |
| `stream` | bool | false | Stream response |
| `stop` | string/array | null | Stop sequences |
| `seed` | int | — | Reproducibility seed |
| `presence_penalty` | float | 0 | Penalize new topics (-2 to 2) |
| `frequency_penalty` | float | 0 | Penalize repetition (-2 to 2) |
| `logprobs` | bool | false | Return log probabilities |
| `top_logprobs` | int | — | How many logprobs per token (0–20) |

## Image Generation

Use the wrapper script for image gen/edit. For raw API details, see [references/api-reference.md](references/api-reference.md).

| Parameter | Values |
|-----------|--------|
| `model` | `gpt-image-1.5`, `gpt-image-1`, `gpt-image-1-mini`, `dall-e-3` |
| `size` | `1024x1024`, `1536x1024`, `1024x1536` (GPT image); `256x256`, `512x512`, `1024x1024`, `1024x1792`, `1792x1024` (DALL-E 3) |
| `quality` | `auto`/`low`/`medium`/`high` (GPT image); `standard`/`hd` (DALL-E 3) |
| `background` | `auto`, `transparent`, `opaque` (GPT image only) |
| `output_format` | `png`, `jpeg`, `webp` (GPT image only) |
| `n` | 1–4 (GPT image); 1 (DALL-E 3) |

GPT image models return `b64_json` by default. DALL-E returns `url` (expires 1 hour). Edit endpoint accepts up to 16 input images.

## Text-to-Speech

**Voices:** `alloy`, `ash`, `ballad`, `coral`, `echo`, `fable`, `nova`, `onyx`, `sage`, `shimmer`, `verse`

| Parameter | Notes |
|-----------|-------|
| `model` | `gpt-4o-mini-tts` (steerable), `tts-1` (fast), `tts-1-hd` (quality) |
| `voice` | Required. See list above. |
| `instructions` | Natural language voice direction (gpt-4o-mini-tts only) |
| `speed` | 0.25–4.0 (tts-1/tts-1-hd only) |
| `response_format` | `mp3`, `opus`, `aac`, `flac`, `wav`, `pcm` (default: mp3) |

Max input: 4096 characters (tts-1/hd), 2000 tokens (gpt-4o-mini-tts). Returns raw audio bytes.

## Speech-to-Text

| Parameter | Notes |
|-----------|-------|
| `model` | `gpt-4o-transcribe`, `gpt-4o-mini-transcribe`, `gpt-4o-transcribe-diarize`, `whisper-1` |
| `language` | ISO-639-1 code (e.g., `en`, `es`, `fr`) |
| `prompt` | Context hint to improve accuracy |
| `response_format` | `json`, `text`, `srt`, `verbose_json`, `vtt` |
| `timestamp_granularities` | `["word"]`, `["segment"]`, or both (verbose_json only) |

Supported audio formats: mp3, mp4, mpeg, mpga, m4a, wav, webm. Max file: 25MB.
Translation endpoint (`/audio/translations`) translates to English (whisper-1 only).

## Embeddings

| Parameter | Notes |
|-----------|-------|
| `model` | `text-embedding-3-small` (1536d), `text-embedding-3-large` (3072d) |
| `input` | String or array of strings (max 8192 tokens per input) |
| `dimensions` | Reduce embedding dimensions (e.g., 256, 512, 1024) |
| `encoding_format` | `float` (default) or `base64` |

## Moderation

Check content against OpenAI's policies. Returns categories (`harassment`, `hate`, `self-harm`, `sexual`, `violence`, etc.) with boolean flags and scores. The `omni-moderation-latest` model also accepts images.

## Responses API

The newer Responses API provides server-side conversation state management and built-in tools. Use it when you need **web search**, **file search**, **code interpreter**, or multi-turn agentic workflows.

Endpoint: `POST /v1/responses`

| Feature | Chat Completions | Responses API |
|---------|-----------------|---------------|
| State | Client-managed (send full history) | Server-managed (`previous_response_id`) |
| Built-in tools | None | web_search, file_search, code_interpreter, computer_use |
| Structured output | `response_format` | `text.format` |

### Built-in Tools

```json
{"tools": [{"type": "web_search_preview"}]}
{"tools": [{"type": "file_search", "vector_store_ids": ["vs_..."]}]}
{"tools": [{"type": "code_interpreter"}]}
```

For full Responses API parameters, see [references/api-reference.md](references/api-reference.md).

## List Models

```bash
bash $SCRIPT models
# or: curl "${BASE}/models" -H "Authorization: Bearer $OPENAI_API_KEY" | jq '.data[] | {id, owned_by}'
```

## Error Handling

All endpoints return JSON errors:

```json
{
  "error": {
    "message": "Human-readable description",
    "type": "error_type",
    "param": "field_name",
    "code": "error_code"
  }
}
```

| HTTP Code | Common Cause | Action |
|-----------|-------------|--------|
| 400 | Invalid request parameters | Fix the request |
| 401 | Invalid API key | Check OPENAI_API_KEY |
| 403 | Insufficient permissions | Check API key scope |
| 429 | Rate limited | Back off, retry with exponential backoff |
| 500 | Server error | Retry |
| 503 | Server overloaded | Retry with backoff |

Rate limit headers: `x-ratelimit-limit-requests`, `x-ratelimit-remaining-requests`, `x-ratelimit-reset-requests` (same for tokens).

## References

- **Full API reference** (all endpoints, all parameters, response schemas): read [references/api-reference.md](references/api-reference.md)
- **OpenAI docs**: https://platform.openai.com/docs
- **API Reference**: https://platform.openai.com/docs/api-reference
- **Models list**: https://platform.openai.com/docs/models
