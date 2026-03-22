---
name: fal
description: >
  Foundational skill for the fal.ai Model API — 600+ generative media models (image, video, audio, LLMs) accessible via HTTP. Use this skill when: (1) generating images from text or other images (FLUX, SDXL, etc.), (2) generating video from text or images, (3) speech-to-text or text-to-speech, (4) running LLMs via fal, (5) any task involving fal.ai model endpoints, (6) discovering available fal models or checking pricing, (7) chaining models via fal workflows, (8) understanding fal API patterns (sync vs queue, file handling, error handling). This is the base fal skill — specialized skills may reference it for specific model categories or workflows.
metadata: {"openclaw": {"emoji": "⚡", "requires": {"env": ["FAL_API_KEY"]}, "primaryEnv": "FAL_API_KEY"}}
---

# fal Model API

Access 600+ generative media models via `scripts/fal.sh`. Two execution modes: synchronous (fast) and queue (reliable).

## Authentication

Set `FAL_API_KEY` environment variable. The wrapper script handles the auth header automatically.

## Wrapper Script

All operations go through `scripts/fal.sh`. Run `bash scripts/fal.sh --help` for full usage.

### Commands

| Command | Purpose |
|---------|---------|
| `run` | Synchronous model execution (fast, simple) |
| `queue` | Queue-based async execution (reliable, recommended) |
| `status` | Poll queue request status |
| `result` | Get queue request result |
| `cancel` | Cancel a queued request |
| `search` | Search/list available models |
| `schema` | Get a model's OpenAPI input/output schema |
| `pricing` | Get model pricing |
| `estimate` | Estimate cost for model usage |

## Model Discovery

fal has 600+ models that change frequently. Use the script to discover models and get their schemas rather than guessing model IDs.

```bash
# Search by capability
bash scripts/fal.sh search --query "text-to-video" --limit 10

# List all models (paginated)
bash scripts/fal.sh search --limit 50

# Paginate with cursor
bash scripts/fal.sh search --limit 50 --cursor CURSOR_FROM_PREVIOUS

# Get a model's exact input/output schema (authoritative source for parameters)
bash scripts/fal.sh schema --endpoint-id fal-ai/flux/dev

# Check pricing
bash scripts/fal.sh pricing --endpoint-id fal-ai/flux/dev
```

Always fetch the schema before calling an unfamiliar model — it tells you exactly what parameters it accepts.

For a quick reference of commonly used model IDs, see [references/models.md](references/models.md). That list is a convenience starting point — live search is always the source of truth.

## Two Execution Modes

### Sync — Fast, Simple

Best for fast models (<10s). Send request, get result directly.

```bash
# Quick image generation
bash scripts/fal.sh run --model fal-ai/flux/dev --prompt "a cat in a spacesuit"

# With full JSON control
bash scripts/fal.sh run --model fal-ai/flux/dev \
  --data '{"prompt":"a cat","image_size":"landscape_4_3","num_images":2}'

# With image input
bash scripts/fal.sh run --model fal-ai/flux/dev/image-to-image \
  --image_url "https://example.com/photo.jpg" --prompt "make it watercolor"
```

### Queue — Reliable, Recommended

Best for slow operations (video gen, batch) or when reliability matters. Submit → poll → retrieve.

**Important:** The queue submit response returns `status_url`, `response_url`, and `cancel_url`. Use these with `--status-url`, `--response-url`, `--cancel-url` — they contain the correct normalized model path. Alternatively, pass `--model` and the script auto-normalizes sub-paths.

```bash
# Step 1: Submit to queue
bash scripts/fal.sh queue --model fal-ai/wan/v2.2-a14b/text-to-video \
  --prompt "a timelapse of a flower blooming"
# Returns: request_id, status_url, response_url, cancel_url

# Step 2: Poll status — use --status-url from queue response (preferred)
bash scripts/fal.sh status --status-url "STATUS_URL_FROM_RESPONSE" --logs
# OR use --model + --request-id (auto-normalizes sub-paths)
bash scripts/fal.sh status --model fal-ai/wan/v2.2-a14b/text-to-video \
  --request-id REQUEST_ID --logs
# Status: IN_QUEUE → IN_PROGRESS → COMPLETED

# Step 3: Get result — use --response-url from queue response (preferred)
bash scripts/fal.sh result --response-url "RESPONSE_URL_FROM_RESPONSE"
# OR use --model + --request-id
bash scripts/fal.sh result --model fal-ai/wan/v2.2-a14b/text-to-video \
  --request-id REQUEST_ID

# Cancel — use --cancel-url from queue response (preferred)
bash scripts/fal.sh cancel --cancel-url "CANCEL_URL_FROM_RESPONSE"
# OR use --model + --request-id
bash scripts/fal.sh cancel --model fal-ai/wan/v2.2-a14b/text-to-video \
  --request-id REQUEST_ID
```

### Queue with webhook (no polling needed)

```bash
bash scripts/fal.sh queue --model fal-ai/flux/dev \
  --prompt "a sunset" --webhook "https://your.app/webhook"
```

## Which Mode to Use

| Scenario | Mode | Why |
|----------|------|-----|
| Fast image gen (FLUX schnell, SDXL) | `run` | Sub-5s, lowest latency |
| High-quality image gen (FLUX dev/pro) | Either | ~5-15s, sync is simpler |
| Video generation | `queue` | 30s–5min, need reliability |
| Batch operations | `queue` | Track multiple requests |
| Production/critical | `queue` | Auto-retries, cancellation |

## Special Headers

Pass via script options:

```bash
# Fail-fast if processing doesn't start in 30s
bash scripts/fal.sh run --model fal-ai/flux/dev --prompt "test" --request-timeout 30

# Disable auto-retries
bash scripts/fal.sh queue --model fal-ai/flux/dev --prompt "test" --no-retry

# Custom output file expiration (seconds)
bash scripts/fal.sh run --model fal-ai/flux/dev --prompt "test" --expire 3600
```

## File Handling

**Input:** Pass file URLs in the JSON body via `--data` or `--image_url`. Any public URL works. Data URIs work for small files.

**Output:** Models return fal CDN URLs (`https://v3.fal.media/files/...`). Guaranteed available 7 days. Download anything you need to keep longer.

## Common Response Patterns

**Image generation:**
```json
{
  "images": [{"url": "https://v3.fal.media/files/...", "width": 1024, "height": 1024, "content_type": "image/jpeg"}],
  "seed": 123456,
  "timings": {"inference": 2.5}
}
```

**Video generation:**
```json
{
  "video": {"url": "https://v3.fal.media/files/...", "content_type": "video/mp4"}
}
```

## Cost Estimation

```bash
# Get unit price
bash scripts/fal.sh pricing --endpoint-id fal-ai/flux/dev

# Estimate cost for multiple units
bash scripts/fal.sh estimate --endpoint-id fal-ai/flux/dev --unit-quantity 10
```

## Error Handling

Errors return a `detail` array with `type` (machine-readable), `msg` (human-readable), `loc` (field path).

Key error types:
- `content_policy_violation` (422) — safety filter triggered, not retryable
- `generation_timeout` (504) — model too slow, may be retryable
- `no_media_generated` (422) — model produced nothing, not retryable
- `image_too_small` / `image_too_large` (422) — dimension issues, check `ctx` for limits

Queue mode auto-retries server errors (503, 504, 429) up to 10 times. 5xx errors are not billed.

## References

- **Full API reference** (all endpoints, headers, webhooks, workflows): read [references/api-reference.md](references/api-reference.md)
- **Common model IDs** (convenience starting point, not exhaustive): read [references/models.md](references/models.md)
- **All models (live)**: https://fal.ai/models
- **Docs**: https://docs.fal.ai/model-apis
