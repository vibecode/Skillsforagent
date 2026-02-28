# OpenAI Chat Completions API Reference

> **Prefer the wrapper script** (`scripts/openai.sh chat`, `stream`) for common operations. This reference is for advanced parameters the script doesn't expose.

Complete parameter reference for `POST /v1/chat/completions`.

## Request Body — Full Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `model` | string | ✅ | — | `gpt-5.2`, `o3`, `o4-mini` (or dated versions) |
| `messages` | array | ✅ | — | Conversation messages array |
| `temperature` | float | — | 1.0 | 0–2. Not supported by o-series |
| `top_p` | float | — | 1.0 | Nucleus sampling. Don't combine with temperature |
| `n` | int | — | 1 | Number of completions |
| `stream` | bool | — | false | SSE streaming |
| `stream_options` | object | — | null | `{"include_usage": true}` for usage in final chunk |
| `stop` | string/array | — | null | Up to 4 stop sequences |
| `max_tokens` | int | — | model max | Legacy. Use max_completion_tokens instead |
| `max_completion_tokens` | int | — | — | Max output tokens. For o-series, includes reasoning tokens |
| `presence_penalty` | float | — | 0 | -2.0 to 2.0. Penalizes new topics |
| `frequency_penalty` | float | — | 0 | -2.0 to 2.0. Penalizes repetition |
| `logit_bias` | map | — | null | Map token IDs to bias (-100 to 100) |
| `logprobs` | bool | — | false | Return log probabilities |
| `top_logprobs` | int | — | — | 0–20 logprobs per position |
| `response_format` | object | — | `{"type":"text"}` | `json_object`, `json_schema`, or `text` |
| `seed` | int | — | — | Reproducibility (best effort) |
| `tools` | array | — | — | Function definitions |
| `tool_choice` | string/object | — | `"auto"` | `auto`, `none`, `required`, or specific |
| `parallel_tool_calls` | bool | — | true | Allow simultaneous tool calls |
| `reasoning_effort` | string | — | — | `low`, `medium`, `high` (o-series + GPT-5.2) |
| `user` | string | — | — | User identifier for abuse detection |
| `store` | bool | — | — | Store completion for retrieval |
| `metadata` | map | — | — | Key-value pairs for filtering stored completions |

## Structured Output — json_schema Details

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

### strict: true Rules

- All fields must be listed in `required`
- `additionalProperties: false` at every object level (including nested)
- No `default` values allowed
- Supported types: `string`, `number`, `integer`, `boolean`, `array`, `object`, `null`
- For optional fields use `anyOf`: `{"anyOf": [{"type": "string"}, {"type": "null"}]}`
- Max nesting depth: 5 levels
- Max 100 properties per object
- Max 500 total schema properties

## Function Calling — Full Flow

### 1. Define tools

```json
{
  "tools": [{
    "type": "function",
    "function": {
      "name": "get_weather",
      "description": "Get current weather for a city",
      "parameters": {
        "type": "object",
        "properties": {
          "location": {"type": "string", "description": "City name"},
          "unit": {"type": "string", "enum": ["celsius", "fahrenheit"]}
        },
        "required": ["location"],
        "additionalProperties": false
      },
      "strict": true
    }
  }]
}
```

### 2. Model returns tool_calls

```json
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": null,
      "tool_calls": [{
        "id": "call_abc123",
        "type": "function",
        "function": {
          "name": "get_weather",
          "arguments": "{\"location\":\"London\",\"unit\":\"celsius\"}"
        }
      }]
    },
    "finish_reason": "tool_calls"
  }]
}
```

### 3. Send results back

Add the assistant message (with tool_calls) to history, then the tool result:

```json
{
  "role": "tool",
  "tool_call_id": "call_abc123",
  "content": "{\"temp\": 15, \"condition\": \"cloudy\"}"
}
```

### 4. Model generates final response

Send the full message history (user → assistant w/ tool_calls → tool results). Model responds with final text.

### tool_choice Options

| Value | Behavior |
|-------|----------|
| `"auto"` | Model decides whether to call tools (default) |
| `"none"` | Never call tools |
| `"required"` | Must call at least one tool |
| `{"type":"function","function":{"name":"get_weather"}}` | Force specific tool |

## Vision — Content Array Format

```json
{
  "role": "user",
  "content": [
    {"type": "text", "text": "Describe this"},
    {"type": "image_url", "image_url": {"url": "https://...", "detail": "auto"}}
  ]
}
```

### detail Levels

| Level | Resolution | Tokens | Use When |
|-------|-----------|--------|----------|
| `low` | 512×512 | 85 fixed | Quick classification, simple questions |
| `high` | Up to 2048px | Variable (scales with image) | Detailed analysis, reading text |
| `auto` | Model decides | Variable | Default, usually fine |

### Input Formats

- URL: `"url": "https://example.com/image.jpg"`
- Base64: `"url": "data:image/png;base64,iVBOR..."`
- Multiple images: add multiple `image_url` objects to the content array

## Reasoning Model Differences (o3, o4-mini)

| Feature | GPT-5.2 | o3 / o4-mini |
|---------|---------|-------------|
| `system` role | ✅ | ❌ Use `developer` |
| `temperature` | ✅ | ❌ |
| `top_p` | ✅ | ❌ |
| `reasoning_effort` | `none`/`low`/`medium`/`high` | `low`/`medium`/`high` |
| `parallel_tool_calls` | ✅ | ❌ (always sequential) |
| Reasoning tokens | Optional | Always (counted in max_completion_tokens) |

## Response Object

```json
{
  "id": "chatcmpl-...",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "gpt-5.2-2025-12-11",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": "Hello! How can I help?"
    },
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 20,
    "total_tokens": 30,
    "completion_tokens_details": {
      "reasoning_tokens": 0,
      "accepted_prediction_tokens": 0,
      "rejected_prediction_tokens": 0
    }
  }
}
```

### finish_reason Values

| Value | Meaning |
|-------|---------|
| `stop` | Natural completion or hit stop sequence |
| `length` | Hit max_tokens / max_completion_tokens |
| `tool_calls` | Model wants to call tools |
| `content_filter` | Content was filtered |

## Streaming Format

Each SSE event:

```
data: {"id":"...","choices":[{"index":0,"delta":{"role":"assistant"},"finish_reason":null}]}
data: {"id":"...","choices":[{"index":0,"delta":{"content":"Hello"},"finish_reason":null}]}
data: {"id":"...","choices":[{"index":0,"delta":{"content":" world"},"finish_reason":null}]}
data: {"id":"...","choices":[{"index":0,"delta":{},"finish_reason":"stop"}]}
data: [DONE]
```

With `stream_options.include_usage: true`, the final chunk before `[DONE]` includes `usage`.

Tool calls in streaming arrive as deltas with `tool_calls` array items built incrementally.
