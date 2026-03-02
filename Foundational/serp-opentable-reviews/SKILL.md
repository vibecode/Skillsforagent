---
name: serp-opentable-reviews
description: >
  Foundational skill for the SerpApi OpenTable Reviews API — scrape structured restaurant
  reviews, ratings, and AI summaries from OpenTable pages. Use when: (1) fetching reviews for
  a specific OpenTable restaurant, (2) getting overall and category ratings (food, service,
  ambience, value, noise) for a restaurant, (3) reading reviewer details, photos, and
  restaurant responses, (4) paginating through all reviews for a restaurant, (5) getting an
  AI-generated summary of a restaurant's reviews, (6) looking up OpenTable restaurant awards,
  (7) any task involving OpenTable review data through SerpApi. This is the base OpenTable
  reviews skill — specialized skills may reference it for restaurant analysis, dining
  recommendations, or review monitoring workflows.
metadata: {"openclaw": {"emoji": "🍽️", "requires": {"env": ["SERPAPI_KEY"]}, "primaryEnv": "SERPAPI_KEY"}}
---

# SerpApi OpenTable Reviews

Scrape structured restaurant reviews and ratings from OpenTable through SerpApi. Single engine covering reviews, ratings, summaries, and awards.

## Setup

Requires `SERPAPI_KEY` environment variable. All requests are GET to `https://serpapi.com/search` with `api_key` parameter.

## API Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `engine` | Yes | Must be `open_table_reviews` |
| `rid` | Yes | OpenTable Restaurant ID — the path after the first `/` in the restaurant URL |
| `open_table_domain` | No | OpenTable domain (default: `opentable.com`). See Localization section |
| `page` | No | Page number (default: `1`). Each page returns 10 reviews |
| `api_key` | Yes | SerpApi API key |
| `no_cache` | No | `true` to force fresh results (costs 1 credit). Don't combine with `async` |

### Finding the Restaurant ID (`rid`)

The `rid` is extracted from the restaurant's OpenTable URL path after the first `/`:

| OpenTable URL | `rid` value |
|---------------|-------------|
| `https://www.opentable.com/r/central-park-boathouse-new-york-2` | `r/central-park-boathouse-new-york-2` |
| `https://www.opentable.com/r/nobu-palo-alto` | `r/nobu-palo-alto` |

## Quick Start

### Fetch Reviews for a Restaurant

```bash
curl -s "https://serpapi.com/search?engine=open_table_reviews&rid=r/central-park-boathouse-new-york-2&api_key=$SERPAPI_KEY"
```

### Fetch a Specific Page

```bash
curl -s "https://serpapi.com/search?engine=open_table_reviews&rid=r/central-park-boathouse-new-york-2&page=5&api_key=$SERPAPI_KEY"
```

### Fetch Reviews from a Localized Domain

```bash
curl -s "https://serpapi.com/search?engine=open_table_reviews&rid=r/some-london-restaurant&open_table_domain=opentable.co.uk&api_key=$SERPAPI_KEY"
```

## Response Structure

### `search_information`

| Field | Description |
|-------|-------------|
| `page` | Current page number |
| `total_pages` | Total number of pages available |

### `reviews_summary`

Always returned. Contains aggregate data for the restaurant.

| Field | Type | Description |
|-------|------|-------------|
| `reviews_count` | Integer | Total number of reviews |
| `ratings_count` | Integer | Total number of ratings |
| `ratings_summary.overall` | Float | Overall average rating (1.0–5.0) |
| `ratings_summary.food` | Float | Average food rating (1.0–5.0) |
| `ratings_summary.service` | Float | Average service rating (1.0–5.0) |
| `ratings_summary.ambience` | Float | Average ambience rating (1.0–5.0) |
| `ratings_summary.value` | Float | Average value rating (1.0–5.0) |
| `ratings_summary.noise` | String | Noise level (e.g., "Quiet", "Moderate", "Energetic") |
| `ratings[]` | Array | Star distribution: `{ stars: 1-5, count: Integer }` |
| `ai_summary` | String | AI-generated summary of all reviews |

### `awards[]`

Optional. Returned when the restaurant has OpenTable awards.

| Field | Type | Description |
|-------|------|-------------|
| `location` | String | Location of the award |
| `name` | String | Name of the award |

### `reviews[]`

Array of individual reviews (10 per page).

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique review identifier |
| `content` | String | Review text (may contain HTML tags) |
| `dined_at` | String | ISO 8601 datetime when the user dined |
| `submitted_at` | String | ISO 8601 datetime when the review was submitted |
| `user.name` | String | Reviewer's name |
| `user.number_of_reviews` | Integer | Total reviews by this user |
| `user.location` | String | Reviewer's location |
| `user.vip` | Boolean | Whether the reviewer is an OpenTable VIP (optional) |
| `user.avatar` | String | Avatar image URL (optional) |
| `rating.overall` | Integer | Overall rating (1–5) |
| `rating.food` | Integer | Food rating (1–5) |
| `rating.service` | Integer | Service rating (1–5) |
| `rating.ambience` | Integer | Ambience rating (1–5) |
| `rating.value` | Integer | Value rating (1–5) |
| `rating.noise` | String | Noise level description |
| `helpfulness.up` | Integer | Number of helpful votes (optional) |
| `helpfulness.score` | Integer | Net helpful score (optional) |
| `images[]` | Array | Review photos with `id`, `timestamp`, and `variants[]` (optional) |
| `response.content` | String | Restaurant's reply to the review (optional) |
| `response.date` | String | ISO 8601 datetime of the reply (optional) |

### Image Variants

When `images[]` is present, each image has `variants[]` with different sizes:

| Size | Description |
|------|-------------|
| `small` | Small thumbnail |
| `medium` | Medium resolution |
| `xlarge` | Extra large |
| `wideMedium` | Wide format, medium |
| `wideLarge` | Wide format, large |

### `serpapi_pagination`

| Field | Description |
|-------|-------------|
| `previous` | Full URL for the previous page (if applicable) |
| `next` | Full URL for the next page (if applicable) |

## Pagination

Each page returns 10 reviews. Use `search_information.total_pages` to know the total count.

**Strategy for collecting all reviews:**

1. First request: get page 1, read `total_pages` from `search_information`
2. Loop from page 2 to `total_pages`, incrementing `page` parameter
3. Collect `reviews[]` from each page

Or follow `serpapi_pagination.next` until it no longer appears.

## Localization

Use `open_table_domain` to target a specific OpenTable region. Defaults to `opentable.com`.

| Domain | Country |
|--------|---------|
| `opentable.com` | United States (default) |
| `opentable.co.uk` | United Kingdom |
| `opentable.ca` | Canada |
| `opentable.com.au` | Australia |
| `opentable.de` | Germany |
| `opentable.fr` | France |
| `opentable.es` | Spain |
| `opentable.it` | Italy |
| `opentable.ie` | Ireland |
| `opentable.nl` | Netherlands |
| `opentable.jp` | Japan |
| `opentable.hk` | Hong Kong |
| `opentable.sg` | Singapore |
| `opentable.com.mx` | Mexico |
| `opentable.com.tw` | Taiwan |
| `opentable.co.th` | Thailand |
| `opentable.ae` | UAE |

This is the full list of supported domains. The `rid` value is the same regardless of domain.

## Common Workflows

### Get Restaurant Overview (Summary + First Page)

```bash
curl -s "https://serpapi.com/search?engine=open_table_reviews&rid=r/nobu-palo-alto&api_key=$SERPAPI_KEY"
```

Read `reviews_summary` for aggregate ratings and `ai_summary` for a quick overview. The first 10 reviews come in `reviews[]`.

### Collect All Reviews for Analysis

```bash
# Page 1 to get total_pages
curl -s "https://serpapi.com/search?engine=open_table_reviews&rid=r/nobu-palo-alto&page=1&api_key=$SERPAPI_KEY"

# Then loop through remaining pages
curl -s "https://serpapi.com/search?engine=open_table_reviews&rid=r/nobu-palo-alto&page=2&api_key=$SERPAPI_KEY"
# ... up to total_pages
```

### Compare Restaurants

Fetch `reviews_summary` for each restaurant and compare:
- `ratings_summary.overall` for overall score
- Individual category scores (food, service, ambience, value)
- `reviews_count` for sample size
- `ai_summary` for quick qualitative comparison

## Error Handling

| Issue | Solution |
|-------|----------|
| `search_metadata.status` is `"Error"` | Check the `error` field for details |
| Invalid `rid` | Verify the ID matches the OpenTable URL path format (`r/restaurant-slug`) |
| Empty `reviews[]` | Restaurant may have no reviews, or page number exceeds `total_pages` |
| Wrong domain | Ensure `open_table_domain` matches where the restaurant is listed |

## Detailed Reference

For complete JSON examples and extended field documentation: see [references/api-reference.md](references/api-reference.md).
