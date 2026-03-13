---
name: exa
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

Wrapper script: `scripts/exa.sh`
Run: `bash scripts/exa.sh <command> [options]`

Auth: Set `EXA_API_KEY` env var. The script handles auth headers automatically.

## Quick Reference

### Search

Web search with inline content retrieval:

```bash
# Basic search
bash scripts/exa.sh search --query "AI startups that raised Series A in 2025" --numResults 10

# With inline content (highlights for fewer tokens)
bash scripts/exa.sh search --query "AI safety research papers" --numResults 5 \
  --contents '{"highlights":{"maxCharacters":4000}}'

# Category-filtered search
bash scripts/exa.sh search --query "agtech companies in the US" --category company --numResults 20

# Domain-filtered with date range
bash scripts/exa.sh search --query "transformer architecture" \
  --includeDomains '["arxiv.org","openreview.net"]' \
  --startPublishedDate "2024-01-01T00:00:00Z"

# Deep search with structured output
bash scripts/exa.sh search --query "AI safety leaders at major labs" --type deep \
  --outputSchema '{"type":"object","properties":{"leader":{"type":"string"},"organization":{"type":"string"}},"required":["leader","organization"]}' \
  --contents '{"text":true}'
```

**Search types:** `auto` (default, fast), `instant` (<200ms), `neural` (semantic), `fast` (hybrid), `deep` (thorough, supports `outputSchema`), `deep-reasoning`, `deep-max` (most thorough).

**Categories:** `company`, `people`, `research paper`, `news`, `tweet`, `personal site`, `financial report`.

**Key params:** `query` (required), `type`, `numResults` (max 100), `category`, `contents`, `includeDomains`/`excludeDomains`, `startPublishedDate`/`endPublishedDate`, `includeText`/`excludeText`, `maxAgeHours`, `subpages`/`subpageTarget`, `moderation`.

### Content Extraction

Extract content from URLs you already have:

```bash
# Full markdown text
bash scripts/exa.sh contents --ids '["https://example.com/article"]' --text true

# Highlights (10x fewer tokens, best for agentic workflows)
bash scripts/exa.sh contents --ids '["https://example.com/article"]' \
  --highlights '{"query":"key findings","maxCharacters":2000}'

# Structured summary via JSON schema
bash scripts/exa.sh contents --ids '["https://example.com"]' \
  --summary '{"query":"Company info","schema":{"type":"object","properties":{"name":{"type":"string"},"industry":{"type":"string"}},"required":["name"]}}'

# Subpage crawling
bash scripts/exa.sh contents --ids '["https://docs.example.com"]' \
  --subpages 10 --subpageTarget '["api","reference","guide"]' \
  --text '{"maxCharacters":5000}'
```

**Content modes (all combinable):**

| Mode | Type | Best For |
|------|------|----------|
| `text` | Extractive markdown | Deep analysis, full context |
| `highlights` | Extractive excerpts | Agent workflows, factual lookups (10x fewer tokens) |
| `summary` | LLM-generated | Quick overviews, structured extraction via JSON schema |

### Find Similar

Find pages similar to a URL:

```bash
bash scripts/exa.sh find-similar --url "https://arxiv.org/abs/2307.06435" --contents '{"text":true}'
```

Same filters and content options as search. Takes `--url` instead of `--query`.

### Answer

Search-grounded AI answer with citations:

```bash
# Basic answer
bash scripts/exa.sh answer --query "What is the latest valuation of SpaceX?" --text true

# Structured answer
bash scripts/exa.sh answer --query "Top 3 AI labs by funding" \
  --outputSchema '{"type":"object","properties":{"labs":{"type":"array","items":{"type":"object","properties":{"name":{"type":"string"},"funding":{"type":"string"}}}}}}'
```

Returns `answer` (string or structured object) + `citations[]`. Supports `--stream true` (SSE).

Rate limit: 10 QPS.

### Research (Async)

Multi-step research with web exploration and synthesis:

```bash
# Start research task
bash scripts/exa.sh research --instructions "Analyze the current state of AI safety research" --model exa-research

# Poll status (returns pending → running → completed)
bash scripts/exa.sh research-poll --researchId abc123

# Poll with events (progress log)
bash scripts/exa.sh research-poll --researchId abc123 --events true

# Stream status updates (SSE)
bash scripts/exa.sh research-poll --researchId abc123 --stream true

# List all research tasks
bash scripts/exa.sh research-list
```

**Models:** `exa-research-fast` (cheapest), `exa-research` (balanced, default), `exa-research-pro` (most thorough).

Supports `--outputSchema` for structured output. Max 15 concurrent tasks.

**Completed response** includes `output.content` (markdown), `output.parsed` (if schema provided), and `costDollars`.

### Chat Completions (OpenAI-Compatible)

Drop-in replacement using the OpenAI SDK pattern. Uses `Authorization: Bearer` (handled by script).

```bash
# Answer via chat
bash scripts/exa.sh chat --model exa --messages '[{"role":"user","content":"Latest AI news"}]'

# Research via chat (streaming)
bash scripts/exa.sh chat --model exa-research --messages '[{"role":"user","content":"Analyze CRISPR developments"}]' --stream true
```

**Model mapping:** `exa` → answer, `exa-research`/`exa-research-pro` → research.

## Content Freshness

Control cache vs live crawl with `maxAgeHours` (works with search, contents, find-similar):

| Value | Behavior |
|-------|----------|
| `24` | Cache if <24h old, else livecrawl |
| `0` | Always livecrawl |
| `-1` | Cache only (fastest) |
| Omit | Livecrawl as fallback (recommended) |

Pair with `livecrawlTimeout` (ms): `--livecrawlTimeout 12000`

## Websets (Entity Sourcing)

Async platform for finding, verifying, and enriching entities at scale. Full lifecycle: create → search → verify → enrich → export.

```bash
# Preview (dry run — see detected entity type, criteria, enrichments)
bash scripts/exa.sh webset-preview --search '{"query":"AI safety researchers","count":10}'

# Create a Webset
bash scripts/exa.sh webset-create \
  --search '{"query":"Marketing agencies in the US focusing on consumer products","count":25}' \
  --enrichments '[{"description":"What city?","format":"text"},{"description":"Employee count?","format":"number"}]'

# Check status
bash scripts/exa.sh webset-get --id ws_abc123

# Get with items expanded
bash scripts/exa.sh webset-get --id ws_abc123 --expand items

# List items (when status is "idle")
bash scripts/exa.sh webset-items --id ws_abc123 --limit 100

# Get single item
bash scripts/exa.sh webset-item --id ws_abc123 --itemId item_xyz

# Add enrichment column after creation
bash scripts/exa.sh webset-enrichment-add --id ws_abc123 --description "Annual revenue?" --format text

# Add another search to existing Webset
bash scripts/exa.sh webset-search --id ws_abc123 --query "Fintech startups" --count 50

# Set up a monitor (scheduled re-search)
bash scripts/exa.sh webset-monitor-create --id ws_abc123 --cadence daily

# Export
bash scripts/exa.sh webset-export --id ws_abc123

# Delete
bash scripts/exa.sh webset-delete --id ws_abc123
```

**Entity types:** `company`, `person`, `article`, `research_paper`, `custom`. Auto-detected from query, or specify in search config.

**Enrichment formats:** `text`, `date`, `number`, `options`, `email`, `phone`. Max 5 criteria, 10 enrichments, 20 options per enrichment.

**Webhooks:** Create webhooks to get notified on events (item created, webset idle, etc.):

```bash
bash scripts/exa.sh webset-webhook-create --events '["webset.item.created","webset.idle"]' --url "https://your.app/webhook"
```

## Error Handling

All errors return `{requestId, error, tag}`. Include `requestId` when debugging.

| Tag | HTTP | Meaning |
|-----|------|---------|
| `INVALID_API_KEY` | 401 | Bad API key |
| `NO_MORE_CREDITS` | 402 | Out of credits |
| `INVALID_REQUEST_BODY` | 400 | Bad request |
| `CONTENT_FILTER_ERROR` | 403 | Moderation block |
| `UNABLE_TO_GENERATE_RESPONSE` | 501 | Generation failed |

Content-specific per-URL errors appear in `statuses[]`: `CRAWL_NOT_FOUND` (404), `CRAWL_TIMEOUT` (408), `CRAWL_LIVECRAWL_TIMEOUT` (408), `SOURCE_NOT_AVAILABLE` (403).

**Rate limits:** `/search` 10 QPS, `/contents` 100 QPS, `/answer` 10 QPS, `/research` 15 concurrent.

## References

- **Search & Content API reference** (full params, filters, response schemas): read [references/search-content-api.md](references/search-content-api.md)
- **Research & Answer API reference** (async patterns, structured output): read [references/research-answer-api.md](references/research-answer-api.md)
- **Websets API reference** (full CRUD lifecycle, enrichments, webhooks, events): read [references/websets-api.md](references/websets-api.md)
- **Docs**: https://exa.ai/docs
