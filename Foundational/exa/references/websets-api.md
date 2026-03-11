# Exa Websets API Reference

Complete reference for the Websets API — async entity sourcing at scale.

**Base URL:** `https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0`
**Auth:** `x-api-key: $EXA_API_KEY`

## Table of Contents

- [Concepts](#concepts)
- [Websets CRUD](#websets-crud)
- [Searches](#searches)
- [Items](#items)
- [Enrichments](#enrichments)
- [Monitors](#monitors)
- [Imports](#imports)
- [Webhooks](#webhooks)
- [Events](#events)
- [Exports](#exports)
- [Pagination](#pagination)

---

## Concepts

**Webset** — A collection of verified, enriched entities found via search. Status: `idle`, `running`, `paused`.

**Search** — A query attached to a Webset that finds items. Auto-detects entity type and criteria from query, or you specify explicitly. Status: `created`, `running`, `completed`, `canceled`.

**Item** — A verified entity (company, person, article, research paper, or custom). Each item has `properties` (type-specific fields), `evaluations` (criteria results with reasoning), and `enrichments` (custom data).

**Enrichment** — A custom data column added to every item. Agent-powered: extracts info from each item's sources. Formats: `text`, `date`, `number`, `options`, `email`, `phone`.

**Criterion** — A verification condition. Each item is evaluated against all criteria with `satisfied: yes/no/unclear` + `reasoning` + `references`.

**Entity types:** `company`, `person`, `article`, `research_paper`, `custom` (with description).

---

## Websets CRUD

### Create

```bash
curl -X POST 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets' \
  -H 'x-api-key: '"$EXA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "search": {
      "query": "Marketing agencies in the US focusing on consumer products",
      "count": 25,
      "entity": {"type": "company"},
      "criteria": [
        {"description": "Agency must be based in the United States"},
        {"description": "Agency must focus on consumer products"}
      ]
    },
    "enrichments": [
      {"description": "What city is this agency headquartered in?", "format": "text"},
      {"description": "How many employees does this company have?", "format": "number"},
      {"description": "Industry focus", "format": "options", "options": [{"label": "B2C"}, {"label": "B2B"}, {"label": "Both"}]}
    ],
    "externalId": "my-project-123",
    "metadata": {"project": "lead-gen"}
  }'
```

**Required:** `search.query` and `search.count`. Everything else (entity, criteria, enrichments) is optional — auto-detected from query when omitted.

**Max:** 5 criteria, 10 enrichments, 20 options per enrichment.

### Preview (Dry Run)

```bash
curl -X POST 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/preview' \
  -H 'x-api-key: '"$EXA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"search": {"query": "AI safety researchers", "count": 10}}'
```

Returns detected entity type, generated criteria, and available enrichment columns without creating a Webset.

### Get

```bash
# By ID or externalId
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{id}' -H 'x-api-key: '"$EXA_API_KEY"

# With items expanded
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{id}?expand=items' -H 'x-api-key: '"$EXA_API_KEY"
```

### List

```bash
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets?limit=50' -H 'x-api-key: '"$EXA_API_KEY"
```

### Update

```bash
curl -X POST 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{id}' \
  -H 'x-api-key: '"$EXA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"metadata": {"stage": "reviewed"}}'
```

### Cancel

```bash
curl -X POST 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{id}/cancel' -H 'x-api-key: '"$EXA_API_KEY"
```

### Delete

```bash
curl -X DELETE 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{id}' -H 'x-api-key: '"$EXA_API_KEY"
```

---

## Searches

Add new searches to an existing Webset.

### Create Search

```bash
curl -X POST 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/searches' \
  -H 'x-api-key: '"$EXA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": "Expanded search for fintech companies",
    "count": 50,
    "behaviour": "override"
  }'
```

`behaviour: "override"` — reuses existing items, re-evaluates criteria, discards non-matching.

### Get / Cancel Search

```bash
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/searches/{searchId}' -H 'x-api-key: '"$EXA_API_KEY"
curl -X POST 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/searches/{searchId}/cancel' -H 'x-api-key: '"$EXA_API_KEY"
```

Search response includes `progress: {found: int, completion: 0-100}`.

---

## Items

### List Items

```bash
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/items?limit=100' -H 'x-api-key: '"$EXA_API_KEY"
```

### Get Item

```bash
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/items/{itemId}' -H 'x-api-key: '"$EXA_API_KEY"
```

### Delete Item

```bash
curl -X DELETE 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/items/{itemId}' -H 'x-api-key: '"$EXA_API_KEY"
```

### Item Structure

```json
{
  "id": "item_abc",
  "object": "webset_item",
  "source": "search",
  "sourceId": "search_xyz",
  "websetId": "ws_123",
  "properties": {
    "type": "company",
    "url": "https://example.com",
    "description": "Marketing agency specializing in...",
    "content": "Full page text...",
    "company": {
      "name": "Acme Agency",
      "location": "New York, NY",
      "employees": 150,
      "industry": "Marketing",
      "about": "Full-service marketing agency...",
      "logoUrl": "https://example.com/logo.png"
    }
  },
  "evaluations": [
    {
      "criterion": "Agency must be based in the United States",
      "satisfied": "yes",
      "reasoning": "The company is headquartered in New York...",
      "references": [{"title": "About Us", "url": "https://example.com/about", "snippet": "..."}]
    }
  ],
  "enrichments": [
    {
      "object": "enrichment_result",
      "enrichmentId": "enr_abc",
      "format": "text",
      "result": ["New York City"],
      "reasoning": "Found in the company's about page...",
      "references": [{"title": "About", "url": "https://...", "snippet": "..."}]
    }
  ],
  "createdAt": "2025-01-15T10:00:00.000Z",
  "updatedAt": "2025-01-15T10:05:00.000Z"
}
```

### Entity Property Types

**Company:** `name`, `location`, `employees`, `industry`, `about`, `logoUrl`
**Person:** `name`, `location`, `position`, `pictureUrl`
**Article:** `author`, `publishedAt`
**Research Paper:** `author`, `publishedAt`
**Custom:** `author`, `publishedAt`

All include: `type`, `url`, `description`, `content` (optional).

---

## Enrichments

### Create Enrichment

```bash
curl -X POST 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/enrichments' \
  -H 'x-api-key: '"$EXA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"description": "What is the company annual revenue?", "format": "text"}'
```

### Enrichment Formats

| Format | Description | Example Result |
|--------|-------------|---------------|
| `text` | Free-form text | `["$50M ARR"]` |
| `number` | Numeric value | `["150"]` |
| `date` | Date value | `["2024-03-15"]` |
| `email` | Email address | `["hello@example.com"]` |
| `phone` | Phone number | `["+1-555-123-4567"]` |
| `options` | Multiple choice | `["B2C"]` |

For `options`, provide choices: `"options": [{"label": "B2C"}, {"label": "B2B"}, {"label": "Both"}]` (1–20 options).

### Get / Delete / Cancel Enrichment

```bash
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/enrichments/{enrichmentId}' -H 'x-api-key: '"$EXA_API_KEY"
curl -X DELETE 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/enrichments/{enrichmentId}' -H 'x-api-key: '"$EXA_API_KEY"
curl -X POST 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/enrichments/{enrichmentId}/cancel' -H 'x-api-key: '"$EXA_API_KEY"
```

---

## Monitors

Scheduled re-searches to keep Websets updated with fresh data.

### Create Monitor

```bash
curl -X POST 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/monitors' \
  -H 'x-api-key: '"$EXA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"cadence": "daily"}'
```

### CRUD

```bash
# List
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/monitors' -H 'x-api-key: '"$EXA_API_KEY"
# Get
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/monitors/{monitorId}' -H 'x-api-key: '"$EXA_API_KEY"
# Update
curl -X POST 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/monitors/{monitorId}' ...
# Delete
curl -X DELETE 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/monitors/{monitorId}' -H 'x-api-key: '"$EXA_API_KEY"
```

### Monitor Runs

```bash
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/monitors/{monitorId}/runs' -H 'x-api-key: '"$EXA_API_KEY"
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/monitors/{monitorId}/runs/{runId}' -H 'x-api-key: '"$EXA_API_KEY"
```

---

## Imports

Upload external data into a Webset (e.g., CSV of companies to enrich).

### CRUD

```bash
# Create
curl -X POST 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/imports' ...
# List
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/imports' -H 'x-api-key: '"$EXA_API_KEY"
# Get
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/imports/{importId}' -H 'x-api-key: '"$EXA_API_KEY"
# Update
curl -X POST 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/imports/{importId}' ...
# Delete
curl -X DELETE 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/imports/{importId}' -H 'x-api-key: '"$EXA_API_KEY"
```

---

## Webhooks

Get notified when events happen in your Websets.

### Create Webhook

```bash
curl -X POST 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/webhooks' \
  -H 'x-api-key: '"$EXA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "events": ["webset.item.created", "webset.idle"],
    "url": "https://your.app/webhook"
  }'
```

Returns `secret` for signature verification (only on creation).

### CRUD

```bash
# List
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/webhooks' -H 'x-api-key: '"$EXA_API_KEY"
# Get
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/webhooks/{webhookId}' -H 'x-api-key: '"$EXA_API_KEY"
# Update
curl -X PATCH 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/webhooks/{webhookId}' ...
# Delete
curl -X DELETE 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/webhooks/{webhookId}' -H 'x-api-key: '"$EXA_API_KEY"
# List attempts
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/webhooks/{webhookId}/attempts' -H 'x-api-key: '"$EXA_API_KEY"
```

### Signature Verification

Webhooks are signed with the `secret` returned at creation. Verify the signature header to ensure authenticity.

---

## Events

### Event Types

| Event | Triggered When |
|-------|---------------|
| `webset.created` | Webset created |
| `webset.deleted` | Webset deleted |
| `webset.paused` | Webset paused |
| `webset.idle` | Webset finished all operations |
| `webset.search.created` | Search started |
| `webset.search.updated` | Search progress updated |
| `webset.search.completed` | Search finished |
| `webset.search.canceled` | Search canceled |
| `webset.item.created` | New item found and verified |
| `webset.item.enriched` | Item enrichment completed |
| `webset.export.created` | Export started |
| `webset.export.completed` | Export finished |

### List Events

```bash
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/events?limit=50' -H 'x-api-key: '"$EXA_API_KEY"

# Get specific event
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/events/{eventId}' -H 'x-api-key: '"$EXA_API_KEY"
```

---

## Exports

### Schedule Export

```bash
curl -X POST 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/exports' -H 'x-api-key: '"$EXA_API_KEY"
```

### Get Export

```bash
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets/{websetId}/exports/{exportId}' -H 'x-api-key: '"$EXA_API_KEY"
```

---

## Pagination

All list endpoints use cursor-based pagination:

```bash
# First page
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets?limit=50' -H 'x-api-key: '"$EXA_API_KEY"

# Next page (use nextCursor from previous response)
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/websets?limit=50&cursor=CURSOR' -H 'x-api-key: '"$EXA_API_KEY"
```

Response always includes:
```json
{
  "data": [...],
  "hasMore": true,
  "nextCursor": "cursor_abc123"
}
```

Max `limit`: 200.

---

## Team Info

```bash
curl 'https://api.exa.ai.cloudproxy.vibecodeapp.com/websets/v0/team' -H 'x-api-key: '"$EXA_API_KEY"
```

Returns concurrency usage and limits.
