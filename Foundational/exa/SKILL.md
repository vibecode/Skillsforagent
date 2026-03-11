---
name: Exa
description: >
  Foundational skill for the Exa API — web search, content extraction, similar link discovery,
  AI-powered answers, multi-step research, and Websets (async entity sourcing at scale). Use
  this skill when: (1) searching the web with semantic/neural/deep search, (2) extracting
  content from URLs as markdown/highlights/summaries, (3) finding pages similar to a given URL,
  (4) getting search-grounded AI answers with citations, (5) running async multi-step research
  tasks, (6) building Websets to find, verify, and enrich entities (companies, people, articles)
  at scale, (7) using Exa's OpenAI-compatible chat completions interface, (8) any task involving
  the Exa API. This is the base Exa skill — specialized skills may reference it.
metadata: {"openclaw": {"emoji": "🔍", "requires": {"env": ["EXA_API_KEY"]}, "primaryEnv": "EXA_API_KEY"}}
---

# Exa API

Web search, content extraction, AI answers, research, and entity sourcing — all via HTTP.

## Authentication

All endpoints at `https://api.exa.ai.cloudproxy.vibecodeapp.com`. Same header everywhere:

```
x-api-key: $EXA_API_KEY
```

## Endpoints Overview

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/search` | POST | Web search with inline content retrieval |
| `/contents` | POST | Extract content from known URLs |
| `/findSimilar` | POST | Find pages similar to a URL |
| `/answer` | POST | Search-grounded AI answer with citations |
| `/research/v1` | POST | Async multi-step research tasks |
| `/websets/v0/...` | CRUD | Entity sourcing at scale (Websets) |
| `/chat/completions` | POST | OpenAI-compatible interface |

## Search

```bash
curl -X POST 'https://api.exa.ai.cloudproxy.vibecodeapp.com/search' \
  -H 'x-api-key: '"$EXA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": "AI startups that raised Series A in 2025",
    "type": "auto",
    "numResults": 10,
    "contents": {
      "highlights": {"maxCharacters": 4000}
    }
  }'
```

**Key parameters:** `query` (required), `type`, `numResults` (max 100), `category`, `contents`, `includeDomains`/`excludeDomains`, `startPublishedDate`/`endPublishedDate`, `includeText`/`excludeText`, `maxAgeHours`, `subpages`/`subpageTarget`, `moderation`.

### Search Types

| Type | Speed | Best For |
|------|-------|----------|
| `auto` (default) | Fast | General — intelligently selects method |
| `instant` | <200ms | Autocomplete, live suggestions |
| `neural` | Fast | Semantic similarity |
| `fast` | Fast | Quick keyword + neural hybrid |
| `deep` | Slower | Comprehensive research, supports `outputSchema` |
| `deep-reasoning` | Slower | Complex reasoning with structured output |
| `deep-max` | Slowest | Maximum thoroughness |

### Categories

`company`, `people`, `research paper`, `news`, `tweet`, `personal site`, `financial report`

```json
{"query": "agtech companies in the US", "category": "company", "numResults": 20}
```

## Content Extraction

Extract content from URLs you already have (no search needed):

```bash
curl -X POST 'https://api.exa.ai.cloudproxy.vibecodeapp.com/contents' \
  -H 'x-api-key: '"$EXA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "ids": ["https://example.com/article"],
    "text": true,
    "highlights": {"query": "key findings", "maxCharacters": 2000}
  }'
```

**Required:** `ids` (array of URLs). Supports same content options as search.

### Content Modes

| Mode | Type | Best For |
|------|------|----------|
| `text` | Extractive markdown | Deep analysis, full context |
| `highlights` | Extractive excerpts | Agent workflows, factual lookups (10x fewer tokens) |
| `summary` | LLM-generated | Quick overviews, structured extraction via JSON schema |

All three can be requested together. Use `highlights` for agentic workflows to minimize token usage.

**Structured summary example:**

```json
{
  "ids": ["https://example.com"],
  "summary": {
    "query": "Company info",
    "schema": {
      "type": "object",
      "properties": {"name": {"type": "string"}, "industry": {"type": "string"}},
      "required": ["name"]
    }
  }
}
```

## Find Similar

```bash
curl -X POST 'https://api.exa.ai.cloudproxy.vibecodeapp.com/findSimilar' \
  -H 'x-api-key: '"$EXA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"url": "https://arxiv.org/abs/2307.06435", "contents": {"text": true}}'
```

Same filters and content options as search. Takes `url` instead of `query`.

## Answer

Search-grounded AI answer with citations:

```bash
curl -X POST 'https://api.exa.ai.cloudproxy.vibecodeapp.com/answer' \
  -H 'x-api-key: '"$EXA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"query": "What is the latest valuation of SpaceX?", "text": true}'
```

Returns `answer` (string or structured object) + `citations[]`. Supports `stream: true` (SSE), `outputSchema` for structured JSON, `text: true` for source content.

## Research (Async)

Multi-step research with web exploration and synthesis:

```bash
# 1. Submit
curl -X POST 'https://api.exa.ai.cloudproxy.vibecodeapp.com/research/v1' \
  -H 'x-api-key: '"$EXA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"instructions": "Analyze the AI safety landscape", "model": "exa-research"}'

# 2. Poll (returns status: pending → running → completed)
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/research/v1/{researchId}' \
  -H 'x-api-key: '"$EXA_API_KEY"

# Or stream status updates:
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/research/v1/{researchId}?stream=true' \
  -H 'x-api-key: '"$EXA_API_KEY"
```

**Models:** `exa-research-fast` (cheapest), `exa-research` (balanced), `exa-research-pro` (most thorough). Supports `outputSchema`. Max 15 concurrent tasks.

## Websets (Entity Sourcing)

Async platform for finding, verifying, and enriching entities at scale. Full lifecycle: create → search → verify against criteria → enrich with custom data → export.

```bash
# Create a Webset
curl -X POST 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets' \
  -H 'x-api-key: '"$EXA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "search": {
      "query": "Marketing agencies in the US that focus on consumer products",
      "count": 25
    },
    "enrichments": [
      {"description": "What city is this agency based in?", "format": "text"},
      {"description": "How many employees?", "format": "number"}
    ]
  }'

# Check status
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{id}' -H 'x-api-key: '"$EXA_API_KEY"

# List items (when status is "idle")
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{id}/items' -H 'x-api-key: '"$EXA_API_KEY"
```

Entity types: `company`, `person`, `article`, `research_paper`, `custom`. Auto-detected from query, or specify explicitly. Enrichment formats: `text`, `date`, `number`, `options`, `email`, `phone`.

## Content Freshness

Control cache vs live crawl with `maxAgeHours` (applies to search, contents, findSimilar):

| Value | Behavior |
|-------|----------|
| `24` | Cache if <24h old, else livecrawl |
| `0` | Always livecrawl |
| `-1` | Cache only (fastest) |
| Omit | Livecrawl as fallback (recommended default) |

Pair with `livecrawlTimeout` (ms) to prevent hanging: `"livecrawlTimeout": 12000`

## Subpage Crawling

Discover and extract content from linked pages:

```json
{
  "ids": ["https://docs.example.com"],
  "subpages": 10,
  "subpageTarget": ["api", "reference", "guide"],
  "text": {"maxCharacters": 5000}
}
```

Works with both `/search` and `/contents`.

## OpenAI-Compatible Interface

Drop-in replacement using the OpenAI SDK pattern:

```bash
# Answer (model: exa)
curl https://api.exa.ai.cloudproxy.vibecodeapp.com/chat/completions \
  -H 'Authorization: Bearer '"$EXA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"model": "exa", "messages": [{"role": "user", "content": "Latest AI news"}]}'

# Research (model: exa-research or exa-research-pro)
curl https://api.exa.ai.cloudproxy.vibecodeapp.com/chat/completions \
  -H 'Authorization: Bearer '"$EXA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"model": "exa-research", "messages": [{"role": "user", "content": "Analyze CRISPR developments"}], "stream": true}'
```

Note: `/chat/completions` uses `Authorization: Bearer` (not `x-api-key`).

## Error Handling

All errors: `{requestId, error, tag}`. Include `requestId` when debugging.

Key tags: `INVALID_API_KEY` (401), `NO_MORE_CREDITS` (402), `INVALID_REQUEST_BODY` (400), `CONTENT_FILTER_ERROR` (403), `UNABLE_TO_GENERATE_RESPONSE` (501).

Content-specific per-URL errors appear in `statuses[]`: `CRAWL_NOT_FOUND` (404), `CRAWL_TIMEOUT` (408), `CRAWL_LIVECRAWL_TIMEOUT` (408), `SOURCE_NOT_AVAILABLE` (403).

Rate limits: `/search` 10 QPS, `/contents` 100 QPS, `/answer` 10 QPS, `/research` 15 concurrent.

## References

- **Search & Content API reference** (full params, filters, response schemas): read [references/search-content-api.md](references/search-content-api.md)
- **Research & Answer API reference** (async patterns, structured output): read [references/research-answer-api.md](references/research-answer-api.md)
- **Websets API reference** (full CRUD lifecycle, enrichments, webhooks, events): read [references/websets-api.md](references/websets-api.md)
- **Docs**: https://exa.ai/docs
- **Full docs index**: https://exa.ai/docs/llms.txt
