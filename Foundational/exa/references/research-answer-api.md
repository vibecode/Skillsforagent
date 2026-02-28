# Exa Research & Answer API Reference

Complete reference for `/answer` and `/research/v1` endpoints.

## Table of Contents

- [Answer (`POST /answer`)](#answer)
- [Research (`POST /research/v1`)](#research)
- [OpenAI-Compatible Interface](#openai-compatible-interface)

---

## Answer

**Endpoint:** `POST https://api.exa.ai/answer`

Search-grounded AI answer with citations. Performs a search and synthesizes results into an answer.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | string | ✅ | Question to answer |
| `text` | boolean | ❌ | Include full text in citation sources (default: false) |
| `stream` | boolean | ❌ | Stream response as SSE events |
| `outputSchema` | object | ❌ | JSON Schema (Draft 7) for structured answer output |

### Response

```json
{
  "answer": "SpaceX's latest valuation is approximately $350 billion.",
  "citations": [
    {
      "id": "https://example.com/spacex-valuation",
      "url": "https://example.com/spacex-valuation",
      "title": "SpaceX Valuation Update",
      "publishedDate": "2025-01-15",
      "author": "John Doe",
      "text": "Full text if text=true..."
    }
  ],
  "costDollars": {"total": 0.005}
}
```

### Structured Output

```json
{
  "query": "Top 3 AI labs by funding",
  "outputSchema": {
    "type": "object",
    "properties": {
      "labs": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "name": {"type": "string"},
            "funding": {"type": "string"}
          }
        }
      }
    }
  }
}
```

When `outputSchema` is provided, `answer` is a structured object instead of a string.

### Streaming (SSE)

With `stream: true`, response is delivered as Server-Sent Events:

```
data: {"answer": "SpaceX", "citations": [...]}
data: {"answer": "'s latest", "citations": [...]}
...
```

### Rate Limit

10 QPS.

---

## Research

**Endpoint:** `POST https://api.exa.ai/research/v1`

Async multi-step research. The system explores the web, gathers sources, synthesizes findings, and returns results with citations.

### Create Task

```bash
curl -X POST 'https://api.exa.ai/research/v1' \
  -H 'x-api-key: '"$EXA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "instructions": "Analyze the current state of AI safety research",
    "model": "exa-research"
  }'
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `instructions` | string | ✅ | Research instructions (max 4096 chars) |
| `model` | string | ❌ | `exa-research-fast`, `exa-research` (default), `exa-research-pro` |
| `outputSchema` | object | ❌ | JSON Schema for structured output |

**Response (201 Created):**

```json
{
  "researchId": "abc123",
  "status": "pending",
  "createdAt": 1709078400000,
  "model": "exa-research",
  "instructions": "Analyze the current state..."
}
```

### Poll Status

```bash
curl 'https://api.exa.ai/research/v1/{researchId}' \
  -H 'x-api-key: '"$EXA_API_KEY"

# With events (progress log):
curl 'https://api.exa.ai/research/v1/{researchId}?events=true' \
  -H 'x-api-key: '"$EXA_API_KEY"
```

### Status Progression

| Status | Description |
|--------|-------------|
| `pending` | Task created, not yet started |
| `running` | Actively researching. `events[]` shows progress. |
| `completed` | Done. `output` contains results. |
| `failed` | Task failed. |

### Completed Response

```json
{
  "researchId": "abc123",
  "status": "completed",
  "createdAt": 1709078400000,
  "finishedAt": 1709078500000,
  "model": "exa-research",
  "instructions": "...",
  "output": {
    "content": "Detailed markdown report...",
    "parsed": {"key": "value"}
  },
  "costDollars": {
    "total": 0.15,
    "numSearches": 12,
    "numPages": 45,
    "reasoningTokens": 8500
  },
  "events": [...]
}
```

- `output.content` — always present, markdown text (or JSON string if `outputSchema` used)
- `output.parsed` — only present when `outputSchema` was provided and output validated

### Stream Status (SSE)

```bash
curl 'https://api.exa.ai/research/v1/{researchId}?stream=true' \
  -H 'x-api-key: '"$EXA_API_KEY"
```

Returns SSE events with the full research object as it progresses.

### List Tasks

```bash
curl 'https://api.exa.ai/research/v1' -H 'x-api-key: '"$EXA_API_KEY"
```

### Models

| Model | Speed | Quality | Best For |
|-------|-------|---------|----------|
| `exa-research-fast` | Fastest | Good | Quick lookups, simple questions |
| `exa-research` | Balanced | High | General research (default) |
| `exa-research-pro` | Slowest | Highest | Complex analysis, thorough coverage |

### Rate Limit

15 concurrent tasks.

---

## OpenAI-Compatible Interface

Exa provides drop-in OpenAI SDK compatibility.

**Important:** These endpoints use `Authorization: Bearer` (not `x-api-key`).

### Answer via Chat Completions

```bash
curl https://api.exa.ai/chat/completions \
  -H 'Authorization: Bearer '"$EXA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "exa",
    "messages": [{"role": "user", "content": "What is quantum computing?"}],
    "extra_body": {"text": true}
  }'
```

### Research via Chat Completions

```bash
curl https://api.exa.ai/chat/completions \
  -H 'Authorization: Bearer '"$EXA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "exa-research",
    "messages": [{"role": "user", "content": "Analyze CRISPR developments"}],
    "stream": true
  }'
```

### Research via Responses API

```bash
curl https://api.exa.ai/responses \
  -H 'x-api-key: '"$EXA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"model": "exa-research", "input": "Summarize CRISPR impact on gene therapy"}'
```

### Model Mapping

| OpenAI Model | Exa Endpoint | Notes |
|-------------|-------------|-------|
| `exa` | `/answer` | Search-grounded answer |
| `exa-research` | `/research/v1` | Multi-step research |
| `exa-research-pro` | `/research/v1` | Thorough research |
