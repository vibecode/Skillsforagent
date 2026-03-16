---
name: Gemini LLM
description: >
  Foundational skill for the Google Gemini API — multimodal AI for text, vision, audio, video,
  code, reasoning, structured output, function calling, embeddings, caching, and file uploads.
  Use when: (1) generating text/chat with Gemini models (2.5-flash, 2.5-pro, 3-flash, 3-pro),
  (2) analyzing images/audio/video/documents, (3) function calling or tool use, (4) structured
  JSON output, (5) embeddings with gemini-embedding-001, (6) token counting, (7) context caching,
  (8) file uploads via Files API, (9) thinking/reasoning models, (10) streaming, (11) any task
  involving the Google Generative Language API or AI Studio. Base Gemini skill — specialized
  skills may reference it. For image generation, see gemini-image.
metadata: {"openclaw": {"emoji": "♊", "requires": {"env": ["GOOGLE_API_KEY"]}, "primaryEnv": "GOOGLE_API_KEY"}}
---

# Gemini API

Google's multimodal AI platform: text, vision, audio, video, code, reasoning, embeddings. All via HTTP.

## Authentication

```
Base URL: https://generativelanguage.googleapis.com.cloudproxy.vibecodeapp.com/v1beta
Header:   x-goog-api-key: ${GOOGLE_API_KEY}
```

The cloud proxy handles credentials. Use `$GOOGLE_API_KEY` as-is.

## Wrapper Script

All API operations go through the wrapper script. It handles auth, model selection, file uploads, JSON extraction, and streaming.

```bash
SCRIPT="$(dirname "$0")/scripts/gemini.sh"  # or use full skill path
```

### Quick Reference

```bash
# List models
bash $SCRIPT models

# Text generation
bash $SCRIPT generate --model gemini-2.5-flash --prompt "Explain quantum computing"
bash $SCRIPT generate --model gemini-2.5-pro --prompt "Write a business plan" --max-tokens 8192

# Chat (multi-turn)
bash $SCRIPT generate --model gemini-2.5-flash \
  --messages '[{"role":"user","parts":[{"text":"Hello"}]},{"role":"model","parts":[{"text":"Hi!"}]},{"role":"user","parts":[{"text":"Tell me a joke"}]}]'

# System instruction
bash $SCRIPT generate --model gemini-2.5-flash --prompt "Translate to French: Hello world" \
  --system "You are a professional translator."

# Streaming
bash $SCRIPT stream --model gemini-2.5-flash --prompt "Write a long story about space"

# Vision (image analysis)
bash $SCRIPT generate --model gemini-2.5-flash --prompt "Describe this image" --image photo.jpg
bash $SCRIPT generate --model gemini-2.5-flash --prompt "Compare these" --image img1.jpg --image img2.jpg

# Audio/Video analysis (via file upload)
bash $SCRIPT generate --model gemini-2.5-flash --prompt "Summarize this audio" --file recording.mp3
bash $SCRIPT generate --model gemini-2.5-flash --prompt "What happens in this video?" --file video.mp4

# Structured output (JSON)
bash $SCRIPT generate --model gemini-2.5-flash --prompt "Extract name, age, city from: John is 30 from NYC" \
  --json-schema '{"type":"object","properties":{"name":{"type":"string"},"age":{"type":"integer"},"city":{"type":"string"}},"required":["name","age","city"]}'

# Thinking/reasoning control
bash $SCRIPT generate --model gemini-2.5-flash --prompt "Solve this math problem: ..." --thinking-budget 8192
bash $SCRIPT generate --model gemini-3-flash-preview --prompt "Complex reasoning task" --thinking-level high

# Embeddings
bash $SCRIPT embed --text "What is the meaning of life?"
bash $SCRIPT embed --texts '["First text","Second text","Third text"]'

# Token counting
bash $SCRIPT count-tokens --model gemini-2.5-flash --prompt "How many tokens is this?"
bash $SCRIPT count-tokens --model gemini-2.5-flash --file large_document.pdf

# File upload & management
bash $SCRIPT upload --file document.pdf
bash $SCRIPT files
bash $SCRIPT delete-file --name "files/abc123"

# Context caching
bash $SCRIPT cache-create --model gemini-2.5-flash --file large_doc.pdf --system "You are an analyst" --ttl 3600
bash $SCRIPT cache-list
bash $SCRIPT cache-delete --name "cachedContents/abc123"
```

### Script Flags Reference

| Command | Required Flags | Optional Flags |
|---------|---------------|----------------|
| `models` | — | — |
| `generate` | `--prompt` or `--messages` | `--model`, `--system`, `--image` (repeatable), `--file` (repeatable), `--max-tokens`, `--temperature`, `--top-p`, `--top-k`, `--stop`, `--json-schema`, `--thinking-budget`, `--thinking-level`, `--tools` (JSON), `--cached-content` |
| `stream` | `--prompt` or `--messages` | Same as `generate` |
| `embed` | `--text` or `--texts` | `--model`, `--task-type` |
| `count-tokens` | `--prompt` or `--file` | `--model` |
| `upload` | `--file` | `--display-name`, `--mime-type` |
| `files` | — | — |
| `delete-file` | `--name` | — |
| `cache-create` | `--model`, `--file` or `--text` | `--system`, `--ttl`, `--display-name` |
| `cache-list` | — | — |
| `cache-delete` | `--name` | — |

## Model Discovery

```bash
bash $SCRIPT models
```

Key models (convenience, not exhaustive — always query live):

| Model | Best For | Context | Notes |
|-------|----------|---------|-------|
| `gemini-2.5-flash` | Fast, cost-effective reasoning | 1M tokens | Thinking model, best price-performance |
| `gemini-2.5-pro` | Complex reasoning, coding | 1M tokens | Most capable 2.5, deep thinking |
| `gemini-2.5-flash-lite` | High throughput, budget | 1M tokens | Fastest/cheapest in 2.5 family |
| `gemini-3-flash-preview` | Frontier performance at low cost | — | Preview, rivaling larger models |
| `gemini-3-pro-preview` | State-of-the-art reasoning | — | Preview, advanced multimodal |
| `gemini-3.1-pro-preview` | Complex agentic tasks | — | Latest preview, strongest |
| `gemini-embedding-001` | Embeddings | 8192 tokens | 3072 dimensions, configurable |

### Model Aliases

| Alias | Points To |
|-------|-----------|
| `gemini-flash-latest` | Latest Flash stable |
| `gemini-flash-lite-latest` | Latest Flash-Lite stable |
| `gemini-pro-latest` | Latest Pro stable |

### Specialized Models (separate endpoints)

| Model | Purpose | Method |
|-------|---------|--------|
| `gemini-3-pro-image-preview` | Image generation (Nano Banana Pro) | `generateContent` |
| `gemini-2.5-flash-image` | Image gen/edit (Nano Banana) | `generateContent` |
| `gemini-2.5-flash-preview-tts` | Text-to-speech | `generateContent` |
| `gemini-2.5-pro-preview-tts` | High-quality TTS | `generateContent` |
| `imagen-4.0-generate-001` | Image generation (Imagen 4) | `predict` |
| `veo-3.0-generate-001` | Video generation (Veo 3) | `predictLongRunning` |

## Generation Config

Pass generation parameters via script flags (`--temperature`, `--top-p`, `--top-k`, `--max-tokens`, `--stop`):

```bash
bash $SCRIPT generate --model gemini-2.5-flash --prompt "Creative story" \
  --temperature 1.5 --top-p 0.9 --max-tokens 4096
```

| Parameter | Script Flag | Type | Default | Description |
|-----------|-------------|------|---------|-------------|
| `temperature` | `--temperature` | float | 1.0 | Randomness (0.0–2.0) |
| `topP` | `--top-p` | float | — | Nucleus sampling |
| `topK` | `--top-k` | int | — | Top-K sampling |
| `maxOutputTokens` | `--max-tokens` | int | — | Max response length |
| `stopSequences` | `--stop` | JSON array | — | Stop generation at these |
| `responseMimeType` | `--json-schema` | — | — | Set automatically when using `--json-schema` |
| `responseSchema` | `--json-schema` | JSON | — | JSON Schema for structured output |
| `thinkingConfig` | `--thinking-budget` / `--thinking-level` | — | — | Control reasoning behavior |

## Thinking / Reasoning

### Gemini 2.5 models — use `--thinking-budget`:

```bash
bash $SCRIPT generate --model gemini-2.5-flash --prompt "Solve step by step: ..." --thinking-budget 8192
```

| Model | Range | Disable | Dynamic (default) |
|-------|-------|---------|-------------------|
| 2.5 Pro | 128–32768 | Cannot disable | `--thinking-budget -1` |
| 2.5 Flash | 0–24576 | `--thinking-budget 0` | `--thinking-budget -1` |
| 2.5 Flash-Lite | 512–24576 | `--thinking-budget 0` | `--thinking-budget -1` |

### Gemini 3 models — use `--thinking-level`:

```bash
bash $SCRIPT generate --model gemini-3-flash-preview --prompt "Complex task" --thinking-level medium
```

| Level | Gemini 3.1 Pro | Gemini 3 Pro | Gemini 3 Flash |
|-------|---------------|-------------|----------------|
| `minimal` | ✗ | ✗ | ✓ |
| `low` | ✓ | ✓ | ✓ |
| `medium` | ✓ | ✗ | ✓ |
| `high` (default) | ✓ | ✓ | ✓ |

## Structured Output (JSON Mode)

Force JSON responses matching a schema with `--json-schema`:

```bash
# Extract structured data
bash $SCRIPT generate --model gemini-2.5-flash \
  --prompt "List 3 planets with name and distance from sun" \
  --json-schema '{"type":"array","items":{"type":"object","properties":{"name":{"type":"string"},"distance_au":{"type":"number"}},"required":["name","distance_au"]}}'

# Classification (enum)
bash $SCRIPT generate --model gemini-2.5-flash \
  --prompt "Classify sentiment: I love this product!" \
  --json-schema '{"type":"string","enum":["positive","negative","neutral"]}'
```

The model's response will be valid JSON matching the schema. Supported schema features: `type`, `properties`, `required`, `items`, `enum`, `description`, `nullable`, `anyOf`.

## Function Calling

Pass function declarations via `--tools` (JSON). The model returns a `functionCall` when it wants to invoke one:

```bash
bash $SCRIPT generate --model gemini-2.5-flash \
  --prompt "What is the weather in London?" \
  --tools '[{"functionDeclarations":[{"name":"get_weather","description":"Get current weather for a location","parameters":{"type":"object","properties":{"location":{"type":"string","description":"City name"}},"required":["location"]}}]}]'
```

The script extracts and returns the `functionCall` object when present. To continue the conversation with function results, use `--messages` with the full multi-turn history including `functionResponse` parts.

### Function calling modes

Set in `toolConfig.functionCallingConfig.mode` (via raw `--tools` JSON or `--messages`):

| Mode | Behavior |
|------|----------|
| `AUTO` (default) | Model decides whether to call a function or respond with text |
| `ANY` | Model always calls a function; optionally restrict with `allowedFunctionNames` |
| `NONE` | No function calls; model responds with text only |

### Returning function results

Build a multi-turn `--messages` array including the function response:

```bash
bash $SCRIPT generate --model gemini-2.5-flash \
  --messages '[
    {"role":"user","parts":[{"text":"What is the weather in London?"}]},
    {"role":"model","parts":[{"functionCall":{"name":"get_weather","args":{"location":"London"}}}]},
    {"role":"function","parts":[{"functionResponse":{"name":"get_weather","response":{"temperature":15,"condition":"cloudy"}}}]}
  ]'
```

## Embeddings

```bash
# Single text
bash $SCRIPT embed --text "What is the meaning of life?"

# With task type
bash $SCRIPT embed --text "Document about AI" --task-type RETRIEVAL_DOCUMENT

# Batch (multiple texts)
bash $SCRIPT embed --texts '["First text","Second text","Third text"]'
```

### Task Types

| Task Type | Use Case |
|-----------|----------|
| `RETRIEVAL_DOCUMENT` | Indexing documents for search |
| `RETRIEVAL_QUERY` | Search queries |
| `SEMANTIC_SIMILARITY` | Comparing text similarity |
| `CLASSIFICATION` | Text classification |
| `CLUSTERING` | Grouping similar texts |
| `QUESTION_ANSWERING` | QA contexts |
| `FACT_VERIFICATION` | Fact checking |
| `CODE_RETRIEVAL_QUERY` | Code search queries |

Default dimensions: 3072. Set `outputDimensionality` in the model config to reduce (e.g., 768, 256).

## File Uploads

The script handles the full resumable upload flow automatically:

```bash
# Upload a file
bash $SCRIPT upload --file document.pdf
bash $SCRIPT upload --file video.mp4 --display-name "my-video"

# List uploaded files
bash $SCRIPT files

# Delete a file
bash $SCRIPT delete-file --name "files/abc123"
```

Files auto-expire after 48 hours. For files >20MB passed to `generate` via `--file`, the script auto-uploads them first.

### Using uploaded files in generation

After uploading, use the returned file URI with `--file`:

```bash
# Upload first
bash $SCRIPT upload --file large_video.mp4
# Returns: {"file": {"uri": "https://...files/abc123", ...}}

# Then use in generation
bash $SCRIPT generate --model gemini-2.5-flash \
  --prompt "Summarize this video" \
  --file "https://generativelanguage.googleapis.com/v1beta/files/abc123"
```

## Context Caching

Cache large inputs to save cost on repeated queries (cached tokens are 75% cheaper):

```bash
# Create cache from a file
bash $SCRIPT cache-create --model gemini-2.5-flash --file large_doc.pdf \
  --system "You are an analyst" --ttl 3600

# Create cache from text
bash $SCRIPT cache-create --model gemini-2.5-flash --text "Very long document..." \
  --system "Analyze this" --ttl 7200

# Use cached content in generation
bash $SCRIPT generate --model gemini-2.5-flash \
  --prompt "Summarize the key findings" \
  --cached-content "cachedContents/CACHE_NAME"

# List and manage caches
bash $SCRIPT cache-list
bash $SCRIPT cache-delete --name "cachedContents/abc123"
```

Minimum token count for caching: 1024 (Flash), 4096 (Pro).

**Important:** When using `--cached-content`, do not repeat the cached content or system instruction — they're already in the cache.

## Token Counting

```bash
bash $SCRIPT count-tokens --model gemini-2.5-flash --prompt "Count my tokens"
bash $SCRIPT count-tokens --model gemini-2.5-flash --file large_document.pdf
```

Returns the total token count as a number.

## Safety Settings

Override default content filtering by including `safetySettings` in `--messages` JSON or via the raw API (see references):

| Category | Thresholds |
|----------|-----------|
| `HARM_CATEGORY_HATE_SPEECH` | `BLOCK_NONE`, `BLOCK_ONLY_HIGH`, `BLOCK_MEDIUM_AND_ABOVE`, `BLOCK_LOW_AND_ABOVE` |
| `HARM_CATEGORY_DANGEROUS_CONTENT` | Same |
| `HARM_CATEGORY_SEXUALLY_EXPLICIT` | Same |
| `HARM_CATEGORY_HARASSMENT` | Same |
| `HARM_CATEGORY_CIVIC_INTEGRITY` | Same |

## Error Handling

| HTTP Code | Common Cause |
|-----------|-------------|
| 400 | Invalid request (bad model name, malformed JSON, unsupported param) |
| 401 | Invalid or missing API key |
| 403 | API key lacks permission for this model |
| 404 | Model not found |
| 429 | Rate limited — back off and retry |
| 500 | Server error — retry with exponential backoff |

## References

For full parameter tables and advanced usage:

- **[references/generation-api.md](references/generation-api.md)** — Complete generateContent/streamGenerateContent params, response schema, multimodal input patterns, system instructions
- **[references/tools-and-functions.md](references/tools-and-functions.md)** — Function calling lifecycle, parallel/compositional calls, tool config, native tools (code execution, Google Search grounding, URL context)
- **[references/files-and-caching.md](references/files-and-caching.md)** — File API details, supported MIME types, caching lifecycle, batch embeddings
