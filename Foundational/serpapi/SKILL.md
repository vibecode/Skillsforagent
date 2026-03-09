---
name: SerpApi
description: >
  Foundational skill for the SerpApi search engine API — structured JSON from 30+ engines
  including Google (web, images, maps, flights, hotels, scholar, news, shopping, jobs,
  finance, trends, ads), YouTube (search, video details, transcripts), Tripadvisor,
  OpenTable, Bing, DuckDuckGo, Walmart, eBay, and more. Use when: (1) searching any
  search engine via SerpApi, (2) Google Flights/Hotels pricing, (3) Google Maps local
  search or place details, (4) YouTube search/video/transcript, (5) Google Scholar
  papers, (6) Google Trends, (7) Tripadvisor/OpenTable reviews, (8) e-commerce search
  (Walmart, eBay), (9) app store search, (10) Google Ads transparency, (11) any task
  involving serpapi.com. Base SerpApi skill — specialized skills reference it.
metadata: {"openclaw": {"emoji": "🔍", "requires": {"env": ["SERPAPI_API_KEY"]}, "primaryEnv": "SERPAPI_API_KEY"}}
---

# SerpApi

Structured JSON data from 30+ search engines via a single API endpoint.

## Setup

Requires `SERPAPI_API_KEY` environment variable. All requests go to `https://serpapi.com.cloudproxy.vibecodeapp.com/search` as GET requests with `engine` and `api_key` parameters.

## Wrapper Script

Use `scripts/serpapi.sh` for all API calls. It handles auth, URL encoding, error handling, and JSON formatting.

```bash
bash scripts/serpapi.sh <engine> [--param value ...]
```

**Global flags:**
- `--no-cache` — force fresh results (costs a search credit)
- `--raw` — skip jq formatting

## Quick Reference

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

## Engine Catalog

| Engine | Key Param | Use Case |
|--------|-----------|----------|
| `google` | `q` | Web search, ads, local results, knowledge graph |
| `google_images` | `q` | Image search with size/color/license/date filters |
| `google_maps` | `q`, `ll` | Local business search, place details |
| `google_maps_reviews` | `data_id` | Business reviews (from maps results) |
| `google_flights` | `departure_id`, `arrival_id` | Flight search, pricing, booking links |
| `google_hotels` | `q`, `check_in_date` | Hotel search, pricing, property details |
| `google_scholar` | `q` | Academic papers, citations, authors |
| `google_news` | `q` | News articles |
| `google_shopping` | `q` | Product search, price comparison |
| `google_jobs` | `q` | Job listings |
| `google_finance` | `q` | Stock/crypto quotes, financials |
| `google_trends` | `q` | Search trends, regional interest, related topics |
| `google_autocomplete` | `q` | Search suggestions |
| `google_ads_transparency_center` | `advertiser_id` or `text` | Advertiser ad history |
| `youtube` | `search_query` | YouTube search |
| `youtube_video` | `v` | Video details, comments, related videos |
| `youtube_video_transcript` | `v` | Video transcripts/captions |
| `tripadvisor` | `q` | Travel search (restaurants, hotels, attractions) |
| `open_table_reviews` | `rid` | Restaurant reviews |
| `bing` | `q` | Bing web search |
| `duckduckgo` | `q` | Privacy-focused search |
| `yahoo` | `p` | Yahoo web search |
| `baidu` | `q` | Chinese web search |
| `yandex` | `text` | Russian web search |
| `naver` | `query` | Korean web search |
| `walmart` | `query` | Walmart products |
| `ebay` | `_nkw` | eBay listings |
| `home_depot` | `q` | Home Depot products |
| `apple_app_store` | `term` | iOS app search |
| `google_play` | `q` | Android app search |

> **Note:** Some engines use non-standard query parameters (`p`, `text`, `query`, `_nkw`, `term`, `search_query`). See the engine catalog above.

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

## Detailed Reference

For complete parameter tables for every engine: read [references/engines.md](references/engines.md).
