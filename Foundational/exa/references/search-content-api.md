# Exa Search & Content API Reference

Complete parameter and response reference for `/search`, `/contents`, and `/findSimilar`.

## Table of Contents

- [Search (`POST /search`)](#search)
- [Contents (`POST /contents`)](#contents)
- [Find Similar (`POST /findSimilar`)](#find-similar)
- [Shared: Content Options](#shared-content-options)
- [Shared: CommonRequest Filters](#shared-commonrequest-filters)
- [Response Schema](#response-schema)

---

## Search

**Endpoint:** `POST https://api.exa.ai/search`

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | string | ✅ | Search query. Supports long, semantic descriptions. |
| `type` | string | ❌ | `auto` (default), `neural`, `fast`, `instant`, `deep`, `deep-reasoning`, `deep-max` |
| `numResults` | int | ❌ | 1–100. Default: 10 |
| `category` | string | ❌ | `company`, `people`, `research paper`, `news`, `tweet`, `personal site`, `financial report` |
| `includeDomains` | string[] | ❌ | Only include results from these domains (max 1200) |
| `excludeDomains` | string[] | ❌ | Exclude results from these domains (max 1200) |
| `startPublishedDate` | ISO 8601 | ❌ | Results published after this date |
| `endPublishedDate` | ISO 8601 | ❌ | Results published before this date |
| `startCrawlDate` | ISO 8601 | ❌ | Results crawled after this date |
| `endCrawlDate` | ISO 8601 | ❌ | Results crawled before this date |
| `includeText` | string[] | ❌ | Results must contain all of these strings |
| `excludeText` | string[] | ❌ | Results must NOT contain any of these strings |
| `maxAgeHours` | int | ❌ | Content freshness control (see Freshness section) |
| `livecrawlTimeout` | int | ❌ | Livecrawl timeout in ms (recommended: 10000–15000) |
| `subpages` | int | ❌ | Number of subpages to crawl per result |
| `subpageTarget` | string[] | ❌ | Keywords to prioritize when selecting subpages |
| `moderation` | boolean | ❌ | Enable content moderation |
| `contents` | object | ❌ | Inline content retrieval (see Content Options) |
| `extras` | object | ❌ | `{links: int, imageLinks: int}` — extract URLs/images from results |

### Deep Search Only

| Parameter | Type | Description |
|-----------|------|-------------|
| `outputSchema` | object | JSON Schema for structured output in `output.content`. Supports `type: "text"` (with optional `description`) or `type: "object"` (with `properties`, max depth 2, max 10 properties) |
| `additionalQueries` | boolean | Auto-expand query with variations |

### Example: Deep Search with Structured Output

```json
{
  "query": "AI safety leaders at major labs",
  "type": "deep",
  "outputSchema": {
    "type": "object",
    "properties": {
      "leader": {"type": "string"},
      "organization": {"type": "string"}
    },
    "required": ["leader", "organization"]
  },
  "contents": {"text": true}
}
```

---

## Contents

**Endpoint:** `POST https://api.exa.ai/contents`

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ids` | string[] | ✅ | URLs to extract content from |
| `text` | bool/object | ❌ | Full markdown text (see Content Options) |
| `highlights` | bool/object | ❌ | Extractive excerpts (see Content Options) |
| `summary` | bool/object | ❌ | LLM-generated summary (see Content Options) |
| `maxAgeHours` | int | ❌ | Content freshness control |
| `livecrawlTimeout` | int | ❌ | Livecrawl timeout in ms |
| `subpages` | int | ❌ | Subpages to crawl per URL |
| `subpageTarget` | string[] | ❌ | Keywords to prioritize for subpages |
| `extras` | object | ❌ | `{links: int, imageLinks: int}` |

---

## Find Similar

**Endpoint:** `POST https://api.exa.ai/findSimilar`

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `url` | string | ✅ | URL to find similar pages for |

Plus all CommonRequest filters and content options (same as search minus `query`, `type`, `category`).

---

## Shared: Content Options

Content options can be passed inline with search (`contents` field) or as top-level fields with `/contents`.

### text

| Field | Type | Description |
|-------|------|-------------|
| `true` | boolean | Return full markdown |
| `maxCharacters` | int | Limit text length |
| `includeHtmlTags` | boolean | Preserve HTML tags |
| `verbosity` | string | `compact` (default), `standard`, `full` |
| `includeSections` | string[] | Only these sections: `header`, `navigation`, `banner`, `body`, `sidebar`, `footer`, `metadata` |
| `excludeSections` | string[] | Exclude these sections |

Note: `verbosity`, `includeSections`, `excludeSections` require `livecrawl: "always"` (or `maxAgeHours: 0`).

**Verbosity levels:**

| Content | compact | standard | full |
|---------|:-------:|:--------:|:----:|
| Main body | ✓ | ✓ | ✓ |
| Image placeholders | | ✓ | ✓ |
| Infobox/metadata | | ✓ | ✓ |
| Navigation | | ✓ | ✓ |
| Footer/legal | | | ✓ |

### highlights

| Field | Type | Description |
|-------|------|-------------|
| `true` | boolean | Default highlights based on search query |
| `query` | string | Custom query for highlight relevance |
| `maxCharacters` | int | Max characters to return |

### summary

| Field | Type | Description |
|-------|------|-------------|
| `true` | boolean | Default summary |
| `query` | string | Custom query to guide summary |
| `schema` | object | JSON Schema for structured extraction (Draft 7) |

---

## Shared: CommonRequest Filters

These apply to `/search`, `/contents`, and `/findSimilar`:

| Filter | Type | Description |
|--------|------|-------------|
| `includeDomains` | string[] | Only these domains (max 1200) |
| `excludeDomains` | string[] | Not these domains (max 1200) |
| `startPublishedDate` | ISO 8601 | Published after |
| `endPublishedDate` | ISO 8601 | Published before |
| `startCrawlDate` | ISO 8601 | Crawled after |
| `endCrawlDate` | ISO 8601 | Crawled before |
| `includeText` | string[] | Must contain all |
| `excludeText` | string[] | Must not contain any |

---

## Response Schema

### Search/FindSimilar Response

```json
{
  "requestId": "b5947044c4b78efa9552a7c89b306d95",
  "searchType": "auto",
  "results": [
    {
      "title": "Article Title",
      "url": "https://example.com/article",
      "id": "https://example.com/article",
      "publishedDate": "2023-11-16T01:36:32.547Z",
      "author": "Author Name",
      "image": "https://example.com/image.png",
      "favicon": "https://example.com/favicon.ico",
      "text": "Full markdown content...",
      "highlights": ["Key excerpt 1", "Key excerpt 2"],
      "highlightScores": [0.95, 0.87],
      "summary": "LLM-generated summary..."
    }
  ],
  "costDollars": {
    "total": 0.005,
    "breakDown": [{"search": 0.005, "contents": 0}]
  }
}
```

Fields `text`, `highlights`, `summary` only present when requested.

### Contents Response

Same `results[]` structure, plus per-URL status reporting:

```json
{
  "results": [...],
  "statuses": [
    {"id": "https://example.com", "status": "success"},
    {
      "id": "https://broken.com",
      "status": "error",
      "error": {"tag": "CRAWL_NOT_FOUND", "httpStatusCode": 404}
    }
  ]
}
```

Always check `statuses[]` for per-URL errors.

### Content Error Tags

| Tag | HTTP | Description |
|-----|------|-------------|
| `CRAWL_NOT_FOUND` | 404 | URL not found |
| `CRAWL_TIMEOUT` | 408 | Page timed out |
| `CRAWL_LIVECRAWL_TIMEOUT` | 408 | livecrawlTimeout exceeded |
| `SOURCE_NOT_AVAILABLE` | 403 | Access denied / paywall |
| `UNSUPPORTED_URL` | — | Not HTTP/HTTPS |
| `CRAWL_UNKNOWN_ERROR` | 500+ | Other crawl errors |
