---
name: SerpApi
displayName: SerpApi Master Router
description: >
  Master router skill for SerpApi search engine APIs. Use this whenever a task
  needs current or web-sourced data from search, news, shopping, product price
  comparison, retailer comparison, Reddit/forum opinion research, maps, hotels, flights,
  jobs, reviews, trends, finance, app stores, YouTube, Tripadvisor, OpenTable, or any
  serpapi.com engine. This skill is valuable because it selects the right SerpApi engine,
  avoids common parameter mistakes, reads the correct response keys, uses the local
  proxy wrapper, and returns concise evidence-backed results instead of generic browsing.
  Use it for prompts like hotels near an airport under a budget, Reddit opinions on two
  tools, compare iPhone prices across retailers, or junior software jobs in a city.
  Specialized skills may reference it, but this skill should be the first stop for
  SerpApi engine routing and API usage.
metadata: {"openclaw": {"emoji": "🔍"}}
---

# SerpApi

Master router for structured search results from SerpApi through the Vibecode proxy.

Use this skill to answer two questions before calling the API:

1. Which engine should be used?
2. Which response fields should be trusted?

The platform recommender should use this skill when a user task needs SerpApi. This skill then performs the second-stage routing: it chooses the exact engine, parameters, and result fields. Do not create one shallow skill per query type when this master router can handle the choice directly.

## Routing Contract

When this skill is active, follow this sequence:

1. Classify the user intent into one of the routes below.
2. Use the matching SerpApi engine and query parameters.
3. Inspect the listed response keys instead of guessing.
4. Only load a specialized skill when the route needs deeper workflow judgment, such as flights, maps venue research, YouTube transcript workflows, Tripadvisor, or OpenTable reviews.
5. Return concise results with links, source names, and caveats about weak matches.

The recommender's job is only to select this master skill. The master skill's job is to decide what gets called.

## Master Decision Table

| If the user asks for... | Use this route | Engine | Key parameters | Read |
|-------------------------|----------------|--------|----------------|------|
| "hotels near JFK under 200" | Lodging search | `google_hotels` | `q`, `check_in_date`, `check_out_date`, `max_price`, `currency`, `gl` | `properties[]` |
| "book flights to New York" | Flight planning | `google_flights` | `departure_id`, `arrival_id`, `outbound_date`, `return_date`, `type` | `best_flights[]`, `other_flights[]` |
| "reddit opinions on Cursor vs Windsurf" | Forum/opinion research | `google` | `q="site:reddit.com ..."` | `organic_results[]` |
| "compare iPhone prices across retailers" | Product price comparison | `google_shopping` first, then marketplace engines if needed | `q`, `gl`, `location` | `shopping_results[]` |
| "junior SWE jobs in SF TypeScript" | Job search | `google_jobs` | `q`, `location`, `gl`, `chips` | `jobs_results[]` |
| "restaurants near this venue" | Local search | `google_maps` | `q`, `location` or `ll`, `type=search` | `local_results[]` |
| "reviews for this place" | Place review retrieval | `google_maps` then `google_maps_reviews` | `data_id` from real maps result | `reviews[]` |
| "latest news on X" | News/current events | `google_news` | `q`, `gl`, `hl` | `news_results[]` |
| "images of X" | Image search | `google_images` | `q`, image filters | `images_results[]` |
| "trend for X vs Y" | Search interest trend | `google_trends` | `q`, `data_type`, `geo`, `date` | `interest_over_time`, related keys |
| "stock quote/company finance" | Finance lookup | `google_finance` | `q` | `summary`, `graph[]`, `news_results[]` |
| "iOS/Android app search" | App marketplace search | `apple_app_store` or `google_play` | `term` or `q`, `store` | `organic_results[]`, nested `items[]` |

If the user asks for something not listed, read [references/engines.md](references/engines.md), pick the closest specific engine, then call it through `scripts/serpapi.sh`.

## Setup

The wrapper uses `SERPAPI_API_KEY` when present. In Chorus runner containers it falls back to the SerpApi cloud-proxy dummy key documented by the environment skill, so agents can call the proxy without user-managed secrets. Requests go to `${SERPAPI_BASE_URL:-https://serpapi.com.proxy.chorus.com}/search.json` with `engine` and `api_key` parameters. When `VIBECODE_API_KEY` is present, the wrapper sends it as `x-api-key` for the proxy.

## Wrapper Script

Use `scripts/serpapi.sh` for API calls. It handles auth, URL encoding, error handling, and JSON formatting.

```bash
bash scripts/serpapi.sh <engine> [--param value ...]
```

**Global flags:**
- `--no-cache` — force fresh results (costs a search credit)
- `--raw` — skip jq formatting

## High-Value Workflows

### Hotels near an airport or venue

Use `google_hotels`, not generic search. Ask for or infer check-in/check-out dates before treating prices as useful; hotel prices without dates are weak evidence.

```bash
bash scripts/serpapi.sh google_hotels \
  --q "hotels near JFK" \
  --check_in_date 2026-06-12 \
  --check_out_date 2026-06-13 \
  --max_price 200 \
  --currency USD \
  --gl us
```

Inspect `properties[]`. Prefer options with a usable rating, review count, location clue, and price. For airports, surface shuttle/transport clues when present. Do not recommend a property only because it is cheapest.

### Reddit or forum opinions

SerpApi does not need a separate Reddit engine for most opinion research. Use `google` with search operators, then summarize linked discussions and dates.

```bash
bash scripts/serpapi.sh google \
  --q "site:reddit.com Cursor vs Windsurf reddit" \
  --gl us \
  --num 10
```

Use `organic_results[]`. Prefer recent, discussion-style pages. Label results as opinions, not facts.

### Product price comparison

Use `google_shopping` first for cross-retailer comparison. Use retailer-specific engines like `amazon`, `walmart`, or `ebay` when the user names a marketplace or when Shopping results are too noisy.

```bash
bash scripts/serpapi.sh google_shopping \
  --q "iPhone 16 Pro 256GB unlocked" \
  --gl us
```

Inspect `shopping_results[]`. Normalize variants before comparing prices. Separate new/refurbished/used, storage size, color, carrier lock, bundles, and seller reliability. A lower price is not automatically the best recommendation.

### Job search

Use `google_jobs` for structured listings. Keep seniority, role, and core skills in `q`; put geography in `location`.

```bash
bash scripts/serpapi.sh google_jobs \
  --q "junior software engineer TypeScript" \
  --location "San Francisco, California" \
  --gl us
```

Inspect `jobs_results[]`. Verify locations because Google Jobs may return remote or out-of-area listings. Use `job_highlights[]`, `detected_extensions`, and descriptions to explain why each role matches.

### Venue or restaurant review checks

First call `google_maps` and collect `data_id` from a real returned place. Then call `google_maps_reviews`. Never invent `data_id`.

```bash
bash scripts/serpapi.sh google_maps \
  --q "Sushi Yasuda New York" \
  --location "New York, New York" \
  --type search

bash scripts/serpapi.sh google_maps_reviews \
  --data_id DATA_ID_FROM_LOCAL_RESULTS \
  --sort_by newestFirst
```

If the exact place is not found, broaden the maps query before falling back to generic web search.

## Response Discipline

- Check `search_metadata.status` and `error` before using results.
- Read the engine's actual response key; do not assume every engine returns `organic_results`.
- Use the first page for quick answers, then paginate only when the result quality is weak or the user asks for breadth.
- Prefer concise extraction with `jq` when the response is large.
- Cite or include links from result objects when making recommendations.
- Tell the user when SerpApi results are sparse, stale-looking, region-mismatched, or variant-mismatched.

## Query Construction

- Use `gl`, `hl`, and `location` when geography affects the answer.
- Use `--no-cache` only when freshness matters enough to spend a search credit.
- Keep constraints structured when the engine supports them: hotel dates/prices, flight dates/airports, job location, maps coordinates.
- Use search operators with `google` for source-scoped research: `site:reddit.com`, `site:news.ycombinator.com`, `intitle:`, exact quotes.
- For ambiguous places, products, or apps, run a broad search first, then a more exact second call.

## Common Calls

### Google Web Search

```bash
bash scripts/serpapi.sh google --q "best coffee beans" --gl us --num 10
```

### Google Flights

```bash
# Round trip
bash scripts/serpapi.sh google_flights --departure_id JFK --arrival_id LAX \
  --outbound_date 2026-04-15 --return_date 2026-04-22

# One-way
bash scripts/serpapi.sh google_flights --departure_id SFO --arrival_id ORD \
  --outbound_date 2026-04-15 --type 2

# Airport autocomplete
bash scripts/serpapi.sh google_flights_autocomplete --q "tokyo"
```

### Google Hotels

```bash
bash scripts/serpapi.sh google_hotels --q "hotels in Paris" \
  --check_in_date 2026-06-01 --check_out_date 2026-06-05

# With filters
bash scripts/serpapi.sh google_hotels --q "hotels Tokyo" \
  --check_in_date 2026-07-01 --check_out_date 2026-07-05 \
  --sort_by 3 --max_price 150
```

### Google Shopping

```bash
bash scripts/serpapi.sh google_shopping --q "iphone 16 pro 256gb unlocked" --gl us
```

### Google Jobs

```bash
bash scripts/serpapi.sh google_jobs --q "junior software engineer TypeScript" \
  --location "San Francisco, California" --gl us
```

### Google Maps

```bash
# Search by query + location
bash scripts/serpapi.sh google_maps --q "italian restaurant" \
  --ll "@40.7455,-74.0083,14z" --type search

# Place details
bash scripts/serpapi.sh google_maps --place_id ChIJT2h1HKZZwokR0kgzEtsa03k

# Reviews
bash scripts/serpapi.sh google_maps_reviews --data_id DATA_ID --sort_by newestFirst
```

### Google Images

```bash
# Basic search
bash scripts/serpapi.sh google_images --q "mountain landscape" --imgsz l

# Transparent PNGs
bash scripts/serpapi.sh google_images --q "company logo" --image_color trans

# Time-filtered
bash scripts/serpapi.sh google_images --q "breaking news" --period_unit d --period_value 1
```

### YouTube

```bash
# Search
bash scripts/serpapi.sh youtube --search_query "learn python" --gl us

# Video details + comments
bash scripts/serpapi.sh youtube_video --v dQw4w9WgXcQ

# Transcript
bash scripts/serpapi.sh youtube_video_transcript --v dQw4w9WgXcQ --language_code en
```

### Google Scholar

```bash
bash scripts/serpapi.sh google_scholar --q "machine learning transformers" --as_ylo 2023
```

### Google Trends

```bash
# Interest over time (multiple queries)
bash scripts/serpapi.sh google_trends --q "bitcoin,ethereum" --data_type TIMESERIES

# Related queries
bash scripts/serpapi.sh google_trends --q "artificial intelligence" --data_type RELATED_QUERIES
```

### Google Finance

```bash
bash scripts/serpapi.sh google_finance --q "GOOGL:NASDAQ"
```

### Tripadvisor

```bash
# Search restaurants
bash scripts/serpapi.sh tripadvisor --q "sushi Tokyo" --ssrc r

# Place details
bash scripts/serpapi.sh tripadvisor_place --place_id 187791
```

### OpenTable Reviews

```bash
bash scripts/serpapi.sh open_table_reviews --rid "r/central-park-boathouse-new-york-2"
```

### Google Ads Transparency

```bash
bash scripts/serpapi.sh google_ads_transparency_center --text "apple.com"
```

### Other Engines

```bash
# Bing
bash scripts/serpapi.sh bing --q "coffee"

# DuckDuckGo
bash scripts/serpapi.sh duckduckgo --q "coffee"

# Walmart
bash scripts/serpapi.sh walmart --query "coffee maker"

# eBay
bash scripts/serpapi.sh ebay --_nkw "vintage camera"

# Apple App Store
bash scripts/serpapi.sh apple_app_store --term "weather"

# Google Play
bash scripts/serpapi.sh google_play --q "fitness tracker" --store apps
```

## Pagination

Pagination varies by engine:

- **Google/Bing:** Offset-based — pass `start` (Google) or `first` (Bing) for next page
- **YouTube Search:** Token-based — pass `serpapi_pagination.next_page_token` as `sp`
- **YouTube Video:** Token-based — pass `comments_next_page_token` or `related_videos_next_page_token` as `next_page_token`
- **Google Maps Reviews:** Token-based — pass `next_page_token`
- **Google Hotels Reviews:** Token-based — pass `next_page_token`
- **OpenTable Reviews:** Page-based — increment `page` parameter
- **Google Scholar:** Offset-based — increment `start` by 10

All responses include `serpapi_pagination` when more pages exist.

## Localization

Most Google engines support:
- `gl` — country code (e.g., `us`, `uk`, `de`)
- `hl` — language code (e.g., `en`, `es`, `fr`)
- `location` — named location for geographic targeting

Non-Google engines may use domain-specific parameters (e.g., `tripadvisor_domain`, `open_table_domain`).

## Error Handling

- Check `search_metadata.status` — should be `"Success"`
- On error, response includes `error` field with message
- Cache is 1h by default; use `--no-cache` for fresh results (costs a credit)
- Don't combine `no_cache` and `async`
- Rate limits depend on your SerpApi plan

## When This Skill Is Not Enough

Use a specialized skill when the task needs a deeper workflow that exists locally, such as flight itinerary analysis, Google Maps venue research, YouTube transcript workflows, Tripadvisor analysis, or OpenTable review analysis. Keep this foundational skill loaded for API mechanics and engine routing.

## Detailed Reference

For complete parameter tables for every engine: read [references/engines.md](references/engines.md).
