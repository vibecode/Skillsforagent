---
name: foreplay
display_name: Foreplay
description: >
  Foundational skill for the Foreplay Public API: competitor ad discovery,
  saved swipe-file ads, boards, Spyder tracked brands, ad details, duplicate
  creative groups, brand lookup, brand analytics, and usage/credit checks. Use
  when: (1) searching Meta/Facebook/Instagram ad creatives, (2) analyzing a
  brand's ads or creative velocity, (3) pulling saved Foreplay swipe-file or
  board ads, (4) looking up Foreplay board/brand/ad IDs, (5) finding duplicate
  ads that reuse the same media, (6) checking Foreplay API usage or credits,
  (7) any task involving public.api.foreplay.co or the Foreplay API.
metadata: {"openclaw": {"requires": {"env": ["FOREPLAY_API_KEY"]}, "primaryEnv": "FOREPLAY_API_KEY"}}
---

# Foreplay API

Foreplay exposes competitor ad intelligence and the user's saved swipe-file data.

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
# Free account/credit state
bash scripts/foreplay.sh usage

# Search the Foreplay discovery ad database
bash scripts/foreplay.sh discovery-ads --query "running shoes" --limit 10 --live true

# Resolve a brand name or domain before fetching ads
bash scripts/foreplay.sh discovery-brands --query "nike" --limit 5
bash scripts/foreplay.sh brand-domain --domain "nike.com" --limit 5

# Fetch ads by resolved brand ID or page ID
bash scripts/foreplay.sh brand-ads --brand_ids "brand_123" --limit 20
bash scripts/foreplay.sh page-ads --page_id "123456789" --limit 20

# Saved library and boards
bash scripts/foreplay.sh swipefile-ads --limit 10 --order saved_newest
bash scripts/foreplay.sh boards --folders true
bash scripts/foreplay.sh board-ads --board_id "board_123" --limit 20

# Single ad detail and duplicate creatives
bash scripts/foreplay.sh ad --ad_id "ad_123"
bash scripts/foreplay.sh /api/ad/duplicates/ad_123
```

## Command Map

All commands are GET requests. You can also pass any documented path directly, for example `bash scripts/foreplay.sh /api/usage`.

| Command | Path | Use |
|---|---|---|
| `usage` | `/api/usage` | Remaining credits and billing window. Free. |
| `swipefile-ads` | `/api/swipefile/ads` | Saved ads in the user's swipe file. |
| `boards` | `/api/boards` | Boards, optionally nested with `--folders true`. |
| `board-brands` | `/api/board/brands` | Brands on a board. Requires `--board_id`. |
| `board-ads` | `/api/board/ads` | Ads on a board. Requires `--board_id`. |
| `spyder-brands` | `/api/spyder/brands` | User's tracked Spyder brands. |
| `spyder-brand` | `/api/spyder/brand` | One Spyder brand. Requires `--brand_id`; returns 403 unless the account is subscribed to that brand. |
| `spyder-brand-ads` | `/api/spyder/brand/ads` | Ads for a tracked Spyder brand. Requires `--brand_id`. |
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
- `--order newest|oldest|longest_running|most_relevant|saved_newest`: `saved_newest` only applies to swipe-file ads.

## Cost Notes

Observed `X-Credit-Cost` on live calls with `--limit 1` (2026-06-09):

- Free: `usage`, `swipefile-ads`, `board-brands`, `board-ads`, `spyder-brands`, `spyder-brand-ads`, `brand-ads`, `brand-analytics`, ad duplicates.
- 1 credit per item returned: `boards`, `discovery-ads`, `discovery-brands`, `discovery-brands-explore`, `brand-domain`, `page-ads`, `ad`.
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

