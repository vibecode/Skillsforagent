---
name: foreplay
display_name: Foreplay
description: >
  Foundational skill for the Foreplay Public API: a curated ad-intelligence
  database of Meta/Facebook/Instagram ad creatives with brand-level discovery,
  ad details, duplicate creative groups, brand lookup, and creative-velocity
  analytics. Use when: (1) searching Foreplay's ad creative database by
  keyword, niche, format, or platform, (2) analyzing a brand's ads or creative
  velocity, (3) resolving brands by name or domain to fetch their ads,
  (4) finding duplicate ads that reuse the same media, (5) any task involving
  public.api.foreplay.co or the Foreplay API. Not for scraping platform ad
  libraries directly (use scrapecreators) or general SERP/ads-transparency
  search (use SerpApi).
metadata: {"openclaw": {"requires": {"env": ["FOREPLAY_API_KEY"]}, "primaryEnv": "FOREPLAY_API_KEY"}}
---

# Foreplay API

Foreplay exposes competitor ad intelligence: a searchable database of Meta ad creatives with brand-level analytics.

Live docs (canonical source for all endpoints and parameters): https://docs.foreplay.co

Wrapper script: `scripts/foreplay.sh`
Run: `bash scripts/foreplay.sh <command-or-path> [--param value ...]`

## Authentication

Use the proxy-provided key already in `FOREPLAY_API_KEY`.

```
Base URL: ${FOREPLAY_BASE_URL:-https://public.api.foreplay.co.proxy.chorus.com}
Header:   Authorization: ${FOREPLAY_API_KEY}
```

For the Chorus proxy, send the dummy key as the raw `Authorization` header value. Do not add `Bearer` unless you are intentionally bypassing the proxy with a real upstream bearer token.

## Quick Start

```bash
# Search the Foreplay discovery ad database
bash scripts/foreplay.sh discovery-ads --query "running shoes" --limit 10 --live true

# Resolve a brand name or domain before fetching ads
bash scripts/foreplay.sh discovery-brands --query "nike" --limit 5
bash scripts/foreplay.sh brand-domain --domain "nike.com" --limit 5

# Fetch ads by resolved brand ID or page ID
bash scripts/foreplay.sh brand-ads --brand_ids "brand_123" --limit 20
bash scripts/foreplay.sh page-ads --page_id "123456789" --limit 20

# Brand creative analytics
bash scripts/foreplay.sh brand-analytics --id "brand_123"

# Single ad detail and duplicate creatives
bash scripts/foreplay.sh ad --ad_id "ad_123"
bash scripts/foreplay.sh /api/ad/duplicates/ad_123
```

## Command Map

All commands are GET requests. You can also pass any path documented in the live docs directly, for example `bash scripts/foreplay.sh /api/ad/duplicates/ad_123`. Account-specific endpoints (swipe file, boards, Spyder tracking, usage) are documented in the live docs but intentionally not mapped here — this skill is for scraping ads data.

| Command | Path | Use |
|---|---|---|
| `ad` | `/api/ad` | Single ad detail. Requires `--ad_id`. |
| `brand-ads` | `/api/brand/getAdsByBrandId` | Ads by Foreplay brand ID. Requires `--brand_ids`. |
| `page-ads` | `/api/brand/getAdsByPageId` | Ads by Meta page ID. Requires `--page_id`. |
| `brand-domain` | `/api/brand/getBrandsByDomain` | Resolve brands by domain. Requires `--domain`. |
| `brand-analytics` | `/api/brand/analytics` | Running ads distribution and creative velocity. Requires `--id`. |
| `discovery-ads` | `/api/discovery/ads` | Search and filter ads across Foreplay discovery. |
| `discovery-brands` | `/api/discovery/brands` | Search brands by name. Requires `--query`. |
| `discovery-brands-explore` | `/api/discovery/brands/explore` | Discover brands by ad characteristics. |

## Common Filters

Ad-list endpoints share these filters:

- `--query`: text search where supported.
- `--start_date`, `--end_date`: date or datetime strings.
- `--live true|false`: active or inactive ads.
- `--display_format video|image|carousel|dco|story|reels`: repeat the flag for multiple values.
- `--publisher_platform facebook|instagram|audience_network|messenger`: repeatable.
- `--niches`, `--market_target`, `--languages`: repeatable filters.
- `--video_duration_min`, `--video_duration_max`: seconds.
- `--running_duration_min_days`, `--running_duration_max_days`: running-duration filters.
- `--cursor` or `--offset`: pagination, depending on endpoint.
- `--limit`: page size. Ad endpoints usually max at 250; brand search endpoints usually max at 10.
- `--order newest|oldest|longest_running|most_relevant`: sort order where supported.

## Cost Notes

Observed `X-Credit-Cost` on live calls with `--limit 1` (2026-06-09):

- Free: `brand-ads`, `brand-analytics`, ad duplicates.
- 1 credit per item returned: `discovery-ads`, `discovery-brands`, `discovery-brands-explore`, `brand-domain`, `page-ads`, `ad`.
- Empty and error responses are normally free.

Prefer small `--limit` values while exploring, then paginate once the query is right.

## Errors

| Status | Meaning |
|---|---|
| 400 | Invalid or missing parameters. |
| 401 | Missing/invalid `FOREPLAY_API_KEY` or wrong auth header shape. |
| 402 | Insufficient Foreplay credits. |
| 403 | The API key does not have access to that Foreplay feature. |
| 404 | No matching resource or result. |
| 422 | Validation failed; inspect the response body for the parameter. |

