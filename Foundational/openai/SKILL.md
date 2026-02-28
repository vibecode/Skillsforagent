---
name: openai
description: >
  Foundational skill for OpenAI text generation — chat completions and reasoning via the latest
  LLMs. Use this skill when: (1) generating text with OpenAI models (GPT-5.2, o3, o4-mini),
  (2) using reasoning models for complex problems, (3) multi-turn conversations, (4) structured
  outputs or JSON mode, (5) function calling / tool use, (6) streaming text generation,
  (7) vision / image understanding as part of text generation, (8) any task involving OpenAI
  chat completions. Includes a wrapper script for common operations. This is the base OpenAI
  LLM skill — covers text generation only, not image gen, TTS, STT, or embeddings.
metadata: {"openclaw": {"emoji": "🤖", "requires": {"env": ["OPENAI_API_KEY"]}, "primaryEnv": "OPENAI_API_KEY"}}
---

# OpenAI Text Generation

Chat completions and reasoning with GPT-5.2, o3, and o4-mini via HTTP.

## Authentication

```
Base URL: https://api.openai.com.cloudproxy.vibecodeapp.com/v1
Header:   Authorization: Bearer $OPENAI_API_KEY
```

The cloud proxy handles credentials. Use `$OPENAI_API_KEY` as-is.

## Models

Three current-gen models. Use `GET /v1/models` for the live list — this is a convenience snapshot.

| Model | Type | Use When |
|-------|------|----------|
| `gpt-5.2` | Flagship | Best overall. Coding, reasoning, agentic tasks, long context |
| `o3` | Reasoning | Complex math, logic, analysis. Uses chain-of-thought internally |
| `o4-mini` | Reasoning (fast) | Reasoning tasks where speed/cost matters more than max quality |

**Reasoning effort** (o3, o4-mini): `low`, `medium`, `high`. GPT-5.2 also supports `reasoning_effort`: `none`, `low`, `medium`, `high`.

## Wrapper Script

> **Prefer the wrapper script** for common operations. It handles auth, JSON construction, streaming, and errors.

```bash
SCRIPT="$(dirname "$0")/scripts/openai.sh"
```

### Quick Reference

```bash
# Basic chat
bash $SCRIPT chat --text "Explain quantum computing" --model gpt-5.2
bash $SCRIPT chat --text "Debug this code: ..." --model o3 --reasoning high

# With system prompt
bash $SCRIPT chat --system "You are a pirate" --text "Tell me about the sea"

# From file
bash $SCRIPT chat --file prompt.txt --model gpt-5.2 --max-tokens 2000

# Streaming
bash $SCRIPT stream --text "Write a long story" --model gpt-5.2

# Vision (image input)
bash $SCRIPT chat --text "What's in this image?" --image photo.jpg --model gpt-5.2

# Structured output (JSON schema)
bash $SCRIPT chat --text "Extract name and age from: John is 30" --model gpt-5.2 \
  --schema '{"type":"object","properties":{"name":{"type":"string"},"age":{"type":"integer"}},"required":["name","age"],"additionalProperties":false}'

# JSON mode (no schema)
bash $SCRIPT chat --text "List 3 fruits as JSON" --model gpt-5.2 --json

# Function calling
bash $SCRIPT chat --text "What's the weather in London?" --model gpt-5.2 --tools tools.json
```

### Script Flags

| Command | Required | Optional |
|---------|----------|----------|
| `chat` | `--text` or `--file` | `--model`, `--system`, `--image`, `--max-tokens`, `--temp`, `--top-p`, `--reasoning`, `--schema`, `--schema-name`, `--json`, `--tools` (JSON file), `--seed`, `--n` |
| `stream` | `--text` or `--file` | Same as `chat` (prints tokens as they arrive) |
| `models` | — | — |

## Chat Completions

`POST /v1/chat/completions`

```bash
curl -X POST "${BASE}/chat/completions" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-5.2",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Hello!"}
    ]
  }'
```

### Key Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `model` | string | required | `gpt-5.2`, `o3`, `o4-mini` |
| `messages` | array | required | Conversation history |
| `temperature` | float | 1.0 | Randomness (0–2). Not supported by o-series |
| `max_completion_tokens` | int | model max | Max output tokens (includes reasoning tokens for o-series) |
| `reasoning_effort` | string | — | `low`/`medium`/`high` for reasoning models |
| `stream` | bool | false | SSE streaming |
| `response_format` | object | `{"type":"text"}` | `json_object`, `json_schema`, or `text` |
| `tools` | array | — | Function definitions |
| `tool_choice` | string/object | `auto` | `auto`, `none`, `required`, or specific function |
| `seed` | int | — | Reproducibility (best effort) |
| `stop` | string/array | null | Up to 4 stop sequences |
| `n` | int | 1 | Number of completions |

### Message Roles

| Role | Purpose |
|------|---------|
| `system` | Behavior/persona. Not supported by o-series (use `developer`) |
| `developer` | Like system, for o-series reasoning models |
| `user` | User input. String or array (for images) |
| `assistant` | Previous model output (multi-turn) |
| `tool` | Tool results. Must include `tool_call_id` |

### Vision

Pass images in the user message `content` array:

```json
{
  "role": "user",
  "content": [
    {"type": "text", "text": "What is in this image?"},
    {"type": "image_url", "image_url": {"url": "https://example.com/photo.jpg", "detail": "auto"}}
  ]
}
```

`detail`: `auto`, `low` (512px, 85 tokens), `high` (full res). Base64: `"url": "data:image/png;base64,..."`.

### Structured Outputs

Force valid JSON matching a schema:

```json
{
  "response_format": {
    "type": "json_schema",
    "json_schema": {
      "name": "person",
      "strict": true,
      "schema": {
        "type": "object",
        "properties": {"name": {"type": "string"}, "age": {"type": "integer"}},
        "required": ["name", "age"],
        "additionalProperties": false
      }
    }
  }
}
```

Rules for `strict: true`: all fields `required`, `additionalProperties: false` at every level, no `default` values, max 5 nesting levels.

Simple JSON mode (no schema): `"response_format": {"type": "json_object"}`.

### Function Calling

1. Define tools in `tools` array
2. Model returns `finish_reason: "tool_calls"` with function name + arguments
3. Execute functions, send results as `tool` role messages with `tool_call_id`
4. Model generates final response

```json
{
  "tools": [{
    "type": "function",
    "function": {
      "name": "get_weather",
      "description": "Get weather for a location",
      "parameters": {
        "type": "object",
        "properties": {"location": {"type": "string"}},
        "required": ["location"],
        "additionalProperties": false
      },
      "strict": true
    }
  }]
}
```

`tool_choice`: `"auto"`, `"none"`, `"required"`, or `{"type": "function", "function": {"name": "..."}}`.

### Streaming

Add `"stream": true`. Responses arrive as SSE:

```
data: {"choices":[{"delta":{"content":"Hello"}}]}
data: {"choices":[{"delta":{"content":" world"}}]}
data: [DONE]
```

Add `"stream_options": {"include_usage": true}` for token counts in the final chunk.

### Reasoning Models (o3, o4-mini)

```json
{
  "model": "o3",
  "messages": [{"role": "user", "content": "Prove sqrt(2) is irrational"}],
  "reasoning_effort": "high"
}
```

Key differences from GPT models:
- No `temperature` or `top_p`
- Use `developer` role instead of `system`
- `max_completion_tokens` includes internal reasoning tokens
- Response includes `completion_tokens_details.reasoning_tokens`

### Response Format

```json
{
  "id": "chatcmpl-...",
  "choices": [{
    "message": {"role": "assistant", "content": "..."},
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 20,
    "total_tokens": 30
  }
}
```

`finish_reason`: `stop`, `length`, `tool_calls`, `content_filter`.

## Error Handling

| HTTP Code | Cause | Action |
|-----------|-------|--------|
| 401 | Invalid API key | Check OPENAI_API_KEY |
| 429 | Rate limited | Exponential backoff |
| 500/503 | Server error | Retry |

Rate limit headers: `x-ratelimit-remaining-requests`, `x-ratelimit-remaining-tokens`.

## References

For full parameter tables: [references/api-reference.md](references/api-reference.md)
