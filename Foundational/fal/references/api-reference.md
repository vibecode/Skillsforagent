# fal Model API — Endpoint Reference

Complete HTTP reference for the fal Model API. Covers synchronous requests, queue-based async requests, file handling, platform APIs, and error handling.

## Table of Contents

- [Domains & URL Structure](#domains--url-structure)
- [Authentication](#authentication)
- [Synchronous Requests](#synchronous-requests)
- [Queue Requests (Recommended)](#queue-requests)
- [Queue Status & Results](#queue-status--results)
- [Cancellation](#cancellation)
- [Webhooks](#webhooks)
- [Special Headers](#special-headers)
- [File Handling](#file-handling)
- [Workflows](#workflows)
- [Platform APIs](#platform-apis)
- [Error Reference](#error-reference)
- [Rate Limits & Reliability](#rate-limits--reliability)

---

## Domains & URL Structure

| Domain | Purpose |
|--------|---------|
| `fal.run` | Synchronous execution |
| `queue.fal.run` | Queue-based async execution (recommended) |
| `api.fal.ai` | Platform management APIs (model search, pricing, usage) |

**There is no `api.fal.ai` domain for model execution.** Only `fal.run` and `queue.fal.run`.

**Model ID format:** `{namespace}/{model}` with optional subpath — e.g., `fal-ai/flux/dev`, `fal-ai/fast-sdxl`, `fal-ai/wan/v2.2-a14b/text-to-video`

---

## Authentication

All requests require the `Authorization` header:

```
Authorization: Key $FAL_KEY
```

Key scopes:
- **API** — model consumption (ready-to-use models)
- **ADMIN** — full access (deploy, private models, CLI)

For consuming models, use API scope.

---

## Synchronous Requests

Best for fast models (<10s). Connection stays open until result is returned.

```bash
curl -X POST "https://fal.run/{model_id}" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "a cat"}'
```

With subpath:

```bash
curl -X POST "https://fal.run/fal-ai/flux/dev" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "a cat", "image_size": "landscape_4_3"}'
```

**Response** — direct model output:

```json
{
  "images": [
    {
      "url": "https://v3.fal.media/files/rabbit/example.jpeg",
      "width": 1024,
      "height": 1024,
      "content_type": "image/jpeg"
    }
  ],
  "timings": {"inference": 2.507},
  "seed": 15860307465884635512,
  "prompt": "a cat"
}
```

**Tradeoffs:**
- ✅ Lowest latency, simplest flow
- ❌ No retries, no cancellation, connection drop = lost result + still billed

---

## Queue Requests

Recommended for all production use and anything >5s. Submit → poll → retrieve.

### Submit

```bash
curl -X POST "https://queue.fal.run/{model_id}" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "a cat"}'
```

**Response:**

```json
{
  "request_id": "80e732af-660e-45cd-bd63-580e4f2a94cc",
  "response_url": "https://queue.fal.run/fal-ai/fast-sdxl/requests/80e732af-...",
  "status_url": "https://queue.fal.run/fal-ai/fast-sdxl/requests/80e732af-.../status",
  "cancel_url": "https://queue.fal.run/fal-ai/fast-sdxl/requests/80e732af-.../cancel"
}
```

### Poll Status

```bash
curl "https://queue.fal.run/{model_id}/requests/{request_id}/status"

# With logs:
curl "https://queue.fal.run/{model_id}/requests/{request_id}/status?logs=1"
```

**Status types:**

| Status | Code | Fields |
|--------|------|--------|
| `IN_QUEUE` | 202 | `queue_position`, `response_url` |
| `IN_PROGRESS` | 202 | `logs[]` (if enabled), `response_url` |
| `COMPLETED` | 200 | `logs[]` (if enabled), `response_url` |

Log entries: `{message, level, source, timestamp}` — levels: `STDERR`, `STDOUT`, `ERROR`, `INFO`, `WARN`, `DEBUG`

### Stream Status (SSE)

Real-time status updates via Server-Sent Events. Connection stays open until `COMPLETED`.

```bash
curl "https://queue.fal.run/{model_id}/requests/{request_id}/status/stream?logs=1"
```

Events are `data:` lines with JSON status objects (same format as poll).

### Get Result

```bash
curl "https://queue.fal.run/{model_id}/requests/{request_id}"
```

Returns the model output directly. HTTP status mirrors the model's status (200 success, 4xx/5xx errors). Returns 404 if request not found, 400 if not yet completed.

---

## Cancellation

Cancel a queued request (only works if status is `IN_QUEUE`):

```bash
curl -X PUT "https://queue.fal.run/{model_id}/requests/{request_id}/cancel"
```

- `202` → `{"status": "CANCELLATION_REQUESTED"}` (may still execute if late in queue)
- `400` → `{"status": "ALREADY_COMPLETED"}`

---

## Webhooks

Get notified when a request completes instead of polling. Append `fal_webhook` query param to queue submit:

```bash
curl -X POST "https://queue.fal.run/fal-ai/flux/dev?fal_webhook=https://your.app/webhook" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "a cat"}'
```

**Webhook payload (success):**
```json
{
  "request_id": "...",
  "gateway_request_id": "...",
  "status": "OK",
  "payload": {
    "images": [...],
    "seed": 123
  }
}
```

**Webhook payload (error):**
```json
{
  "request_id": "...",
  "status": "ERROR",
  "error": "Invalid status code: 422",
  "payload": {
    "detail": [...]
  }
}
```

Webhook retry: 10 attempts over 2 hours, 15s timeout per attempt. Design handlers to be idempotent.

---

## Special Headers

| Header | Value | Description |
|--------|-------|-------------|
| `X-Fal-Object-Lifecycle-Preference` | `{"expiration_duration_seconds": 3600}` | Control how long output files (images, video) remain available |
| `X-Fal-Request-Timeout` | `30` (seconds) | Fail-fast: 504 if processing doesn't start within timeout. Applies to wait time, not inference. |
| `X-Fal-No-Retry` | `1` | Disable automatic retries for this request |
| `X-Fal-Store-IO` | `0` | Prevent input/output payloads from being stored on fal platform |

---

## File Handling

### Input Files (Images, Video, Audio)

Models accept file inputs as **URLs** in the JSON body. Any publicly accessible URL works:

```json
{
  "image_url": "https://example.com/photo.jpg",
  "prompt": "remove the background"
}
```

**Data URIs** also work for small files:

```json
{
  "image_url": "data:image/png;base64,iVBORw0KGgo..."
}
```

### Output Files

Model outputs contain fal CDN URLs:

```json
{
  "url": "https://v3.fal.media/files/rabbit/example.jpeg",
  "width": 1024,
  "height": 1024,
  "content_type": "image/jpeg"
}
```

**Output file retention:** Guaranteed available for **7 days minimum**. Download and store anything you need to keep longer. Use `X-Fal-Object-Lifecycle-Preference` header to customize expiration.

---

## Workflows

Chain multiple models in a pipeline. Same queue endpoints, but with `workflows/` prefix:

```bash
curl -X POST "https://queue.fal.run/workflows/{owner}/{name}" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "a cute puppy"}'
```

Workflows support SSE streaming with events: `submit` (step started), `completion` (step done with output), `output` (final result), `error`.

---

## Platform APIs

Management APIs at `https://api.fal.ai/v1`. Same `Authorization: Key $FAL_KEY` header.

### Model Search

```bash
# List all models
curl "https://api.fal.ai/v1/models?limit=50" -H "Authorization: Key $FAL_KEY"

# Find specific model(s)
curl "https://api.fal.ai/v1/models?endpoint_id=fal-ai/flux/dev" -H "Authorization: Key $FAL_KEY"

# Search by query
curl "https://api.fal.ai/v1/models?query=text-to-video" -H "Authorization: Key $FAL_KEY"

# Include OpenAPI schema
curl "https://api.fal.ai/v1/models?endpoint_id=fal-ai/flux/dev&expand=openapi-3.0" -H "Authorization: Key $FAL_KEY"
```

### Pricing

```bash
curl "https://api.fal.ai/v1/models/pricing?endpoint_id=fal-ai/flux/dev" \
  -H "Authorization: Key $FAL_KEY"
```

Returns: `{prices: [{endpoint_id, unit_price, unit, currency}]}`

### Cost Estimate

```bash
curl -X POST "https://api.fal.ai/v1/models/pricing/estimate" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "estimate_type": "unit_price",
    "endpoints": {
      "fal-ai/flux/dev": {
        "unit_quantity": 10
      }
    }
  }'
```

---

## Error Reference

Error responses have a `detail` array:

```json
{
  "detail": [
    {
      "loc": ["body", "prompt"],
      "msg": "field required",
      "type": "value_error.missing",
      "url": "https://docs.fal.ai/errors/#value_error.missing"
    }
  ]
}
```

| Field | Description |
|-------|-------------|
| `loc` | Error location array (e.g., `["body", "field_name"]`) |
| `msg` | Human-readable message (do not parse programmatically) |
| `type` | Machine-readable error type (use for conditional logic) |
| `url` | Documentation link |
| `ctx` | Optional additional context object |

**Common error types:**

| Type | Status | Retryable | Description |
|------|--------|-----------|-------------|
| `internal_server_error` | 500 | Maybe | Unexpected server issue |
| `generation_timeout` | 504 | Maybe | Model took too long |
| `content_policy_violation` | 422 | No | Content flagged by safety filter |
| `no_media_generated` | 422 | No | Model produced no output |
| `image_too_small` | 422 | No | Image below minimum dimensions (check `ctx.min_height/min_width`) |
| `image_too_large` | 422 | No | Image above maximum dimensions (check `ctx.max_height/max_width`) |
| `downstream_service_error` | 400 | Maybe | External service issue |
| `downstream_service_unavailable` | 500 | Maybe | External service down |

Check `X-Fal-Retryable` response header for retry decisions.

---

## Rate Limits & Reliability

**Concurrency limits:**
- Default: 2 concurrent tasks
- $1000+ credits: 40 concurrent tasks
- Enterprise: custom

Excess requests are **queued automatically** (not rejected).

**Auto-retries (queue only):**
- Retries on: 503, 504, 429, connection errors
- Up to 10 retries with backoff
- Disable per-request with `X-Fal-No-Retry: 1`
- Cap retry time with `X-Fal-Request-Timeout`

**Model fallbacks:** Enabled by default. After 5 failed retries, requests may be routed to equivalent alternative endpoints. Disable per-request with `X-App-Fal-Disable-Fallbacks` header.

**Billing:** 5xx server errors are **not billed**. 4xx client errors (invalid input) are billed.

**Output payloads:** Stored for 30 days by default. Use `X-Fal-Store-IO: 0` to prevent storage.