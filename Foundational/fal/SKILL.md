---
name: Fal
description: >
  Foundational skill for the fal.ai Model API — 600+ generative media models (image, video, audio, LLMs) accessible via HTTP. Use this skill when: (1) generating images from text or other images (FLUX, SDXL, etc.), (2) generating video from text or images, (3) speech-to-text or text-to-speech, (4) running LLMs via fal, (5) any task involving fal.ai model endpoints, (6) discovering available fal models or checking pricing, (7) chaining models via fal workflows, (8) understanding fal API patterns (sync vs queue, file handling, error handling). This is the base fal skill — specialized skills may reference it for specific model categories or workflows.
metadata: {"openclaw": {"emoji": "⚡", "requires": {"env": ["FAL_API_KEY"]}, "primaryEnv": "FAL_API_KEY"}}
---

# fal Model API

Access 600+ generative media models via simple HTTP requests. Two execution modes: synchronous (fast) and queue (reliable).

## Authentication

All requests use the same header:

```
Authorization: Key $FAL_API_KEY
```

## Model Discovery

fal has 600+ models that change frequently. Always use the live Platform API to find models and get their exact input/output schemas rather than guessing or relying on memorized model IDs.

### Find Models

```bash
# Search by keyword (text-to-video, image generation, speech-to-text, etc.)
curl "https://api.fal.ai/v1/models?query=text-to-video&limit=10" \
  -H "Authorization: Key $FAL_API_KEY"

# List all available models (paginated)
curl "https://api.fal.ai/v1/models?limit=50" \
  -H "Authorization: Key $FAL_API_KEY"

# Paginate with cursor
curl "https://api.fal.ai/v1/models?limit=50&cursor=CURSOR_FROM_PREVIOUS" \
  -H "Authorization: Key $FAL_API_KEY"
```

### Get a Model's Input/Output Schema

Before calling any model, fetch its OpenAPI schema to know exactly what parameters it accepts:

```bash
curl "https://api.fal.ai/v1/models?endpoint_id=fal-ai/flux/dev&expand=openapi-3.0" \
  -H "Authorization: Key $FAL_API_KEY"
```

This returns the full OpenAPI 3.0 spec — input parameters, types, defaults, required fields, and output schema. This is the authoritative source for any model's interface.

### Check Pricing

```bash
curl "https://api.fal.ai/v1/models/pricing?endpoint_id=fal-ai/flux/dev" \
  -H "Authorization: Key $FAL_API_KEY"
```

### When to Use Discovery

- **No specific model requested** — search by capability (`query=text-to-image`)
- **Unknown input format** — fetch the OpenAPI schema before calling
- **Choosing between models** — compare options by searching a category
- **Specific model requested** — can skip search, but still fetch schema if unsure of params

For a quick reference of commonly used model IDs, see [references/models.md](references/models.md). That list is a convenience starting point — the live API above is always the source of truth.

## Two Execution Modes

### Sync — Fast, Simple

`POST https://fal.run/{model_id}` — send request, get result directly. Best for fast models (<10s).

```bash
curl -X POST "https://fal.run/fal-ai/flux/dev" \
  -H "Authorization: Key $FAL_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "a cat in a spacesuit", "image_size": "landscape_4_3"}'
```

Returns the model output directly (images, video URLs, text, etc.).

### Queue — Reliable, Recommended

`POST https://queue.fal.run/{model_id}` — submit, poll, retrieve. Built-in retries, cancellation, status tracking. Use for anything slow (video gen, batch ops) or when reliability matters.

**Step 1: Submit**
```bash
curl -X POST "https://queue.fal.run/fal-ai/flux/dev" \
  -H "Authorization: Key $FAL_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "a cat in a spacesuit"}'
```
Returns `request_id`, `status_url`, `response_url`, `cancel_url`.

**Step 2: Poll status**
```bash
curl "https://queue.fal.run/fal-ai/flux/dev/requests/{request_id}/status?logs=1"
```
Status progression: `IN_QUEUE` (202) → `IN_PROGRESS` (202) → `COMPLETED` (200)

**Step 3: Get result**
```bash
curl "https://queue.fal.run/fal-ai/flux/dev/requests/{request_id}"
```

**Cancel** (while `IN_QUEUE`):
```bash
curl -X PUT "https://queue.fal.run/fal-ai/flux/dev/requests/{request_id}/cancel"
```

**SSE streaming** (real-time status updates):
```bash
curl "https://queue.fal.run/fal-ai/flux/dev/requests/{request_id}/status/stream?logs=1"
```

## Which Mode to Use

| Scenario | Mode | Why |
|----------|------|-----|
| Fast image gen (FLUX schnell, SDXL) | Sync | Sub-5s, lowest latency |
| High-quality image gen (FLUX dev/pro) | Either | ~5-15s, sync is simpler |
| Video generation | Queue | 30s–5min, need reliability |
| Batch operations | Queue | Track multiple requests |
| Production/critical | Queue | Auto-retries, cancellation |

## File Handling

**Input:** Pass file URLs in the JSON body. Any public URL works. Data URIs work for small files.

```json
{"image_url": "https://example.com/photo.jpg", "prompt": "remove background"}
```

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

## Error Handling

Errors return a `detail` array with `type` (machine-readable), `msg` (human-readable), `loc` (field path).

Key error types:
- `content_policy_violation` (422) — safety filter triggered, not retryable
- `generation_timeout` (504) — model too slow, may be retryable
- `no_media_generated` (422) — model produced nothing, not retryable
- `image_too_small` / `image_too_large` (422) — dimension issues, check `ctx` for limits

Check `X-Fal-Retryable` response header. Queue mode auto-retries server errors (503, 504, 429) up to 10 times. 5xx errors are not billed.

## Useful Headers

| Header | Purpose |
|--------|---------|
| `X-Fal-Request-Timeout: 30` | Fail-fast if processing doesn't start in 30s |
| `X-Fal-No-Retry: 1` | Disable auto-retries (queue mode) |
| `X-Fal-Object-Lifecycle-Preference: {"expiration_duration_seconds": 3600}` | Custom output file expiration |

## References

- **Full API reference** (all endpoints, headers, webhooks, workflows): read [references/api-reference.md](references/api-reference.md)
- **Common model IDs** (convenience starting point, not exhaustive): read [references/models.md](references/models.md)
- **All models (live)**: https://fal.ai/models
- **Docs**: https://docs.fal.ai/model-apis