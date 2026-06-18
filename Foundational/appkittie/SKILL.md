---
name: appkittie
display_name: AppKittie App Analytics
description: >
  Foundational skill for the AppKittie App Store intelligence API: search and
  filter 2M+ iOS apps with revenue/download estimates, multi-window growth,
  ratings, ad signals, full app detail (metadata, IAPs, creator deals,
  historical rank/review/revenue/download series), and ASO keyword difficulty.
  Ad creatives are fetched separately via the ads/ad commands, not embedded in
  app detail. Use when: (1) discovering trending or fast-growing apps, (2) app
  analytics - downloads, revenue, ratings, reviews for any iOS app, (3) market
  research on a category, niche, or competitor set, (4) finding high-revenue
  apps or revenue benchmarking, (5) ASO keyword difficulty and opportunity
  research, (6) ad intelligence - which apps run Meta or Apple Search Ads,
  (7) any task involving the AppKittie API. Base AppKittie skill - specialized
  skills may reference it.
metadata: {"openclaw": {"emoji": "📱", "requires": {"env": ["APPKITTIE_API_KEY"]}, "primaryEnv": "APPKITTIE_API_KEY"}}
---

# AppKittie

App Store intelligence API: search 2M+ iOS apps by category, revenue, downloads, growth, ratings, and ad signals; pull full per-app analytics; score ASO keywords. JSON output, cursor pagination.

## Authentication

```
Base URL: https://www.appkittie.com.proxy.chorus.com/api/v1
Auth:     Authorization: Bearer ${APPKITTIE_API_KEY} (header on every request)
```

`APPKITTIE_API_KEY` is pre-set in your environment like the other proxy keys (`SERPAPI_API_KEY`, `EXA_API_KEY`, ...). The value is a placeholder; the proxy recognizes it and swaps in a real credential. You do not need to obtain or manage an API key yourself. Override the proxy host with `APPKITTIE_BASE_URL` if needed (host only, no `/api/v1` path).

## Credits & Rate Limits

Every call spends credits from a shared balance:

| Call | Credits |
|------|---------|
| App search (`apps`) | 1 per app returned - keep `limit` small |
| App detail (`app`) | 1 per call |
| Ad search (`ads`) | 1 per ad returned |
| Ad detail (`ad`) | 1 per call |
| Reviews (`reviews`) | 1 per review returned - keep `maxReviews` small |
| Keyword (single) | 10 per call |
| Keyword (batch) | 10 per keyword that returns data |

Rate limit is a 60-second sliding window per key. Responses include `X-RateLimit-Remaining` / `X-RateLimit-Reset` and `X-Credits-Used` / `X-Credits-Remaining` headers. On HTTP 429, wait for the window to roll and retry. On HTTP 402 the balance is exhausted - **stop retrying**, no amount of waiting helps.

**Be deliberate with `limit`:** searching with `limit=50` costs 50 credits. Start with 10-20 rows, then `app` detail only the shortlist.

## Wrapper Script

Use `scripts/appkittie.sh` for all API calls. It handles auth, URL encoding, error handling, and JSON formatting.

```bash
bash scripts/appkittie.sh <command> [--param value ...]
```

### Trending & Growth Discovery

```bash
# What's trending right now
bash scripts/appkittie.sh apps --sortBy trending --limit 20

# Fastest growers this week
bash scripts/appkittie.sh apps --growthPeriod 7d --sortBy growth --sortOrder desc --limit 20

# Sustained 30-day momentum in a category
bash scripts/appkittie.sh apps --categories "Health & Fitness" --growthPeriod 30d --sortBy growth --sortOrder desc --limit 15

# Fresh launches gaining traction (released in the last ~30 days, Unix seconds)
bash scripts/appkittie.sh apps --releasedAfter "$(date -d '30 days ago' +%s 2>/dev/null || date -v-30d +%s)" --sortBy downloads --limit 15
```

### Market Research

```bash
# Top earners in a category - revenue ceiling check
bash scripts/appkittie.sh apps --categories "Health & Fitness" --sortBy revenue --sortOrder desc --limit 10

# High-revenue niche slice by text search
bash scripts/appkittie.sh apps --search meditation --minRevenue 10000 --sortBy revenue --limit 10

# Indie-sized opportunities: real revenue, modest review counts
bash scripts/appkittie.sh apps --categories Productivity --minRevenue 1000 --maxReviews 5000 --sortBy revenue --limit 15

# Who is buying users - Meta ads + revenue correlation
bash scripts/appkittie.sh apps --categories Productivity --hasMetaAds true --sortBy revenue --limit 15

# Paid-app landscape in a niche
bash scripts/appkittie.sh apps --search "sleep tracker" --priceType paid --sortBy revenue --limit 10
```

### App Analytics (single app)

```bash
# Full detail: metadata, revenue/download estimates, IAP catalog, creator
# deals, historical rank/review/revenue/download series
bash scripts/appkittie.sh app --id 1234567890
```

The `--id` is the numeric App Store id (the number after `/id` in an App Store URL). Find it with an `apps` search first if you only have the name. Ad creatives are NOT embedded in app detail - use `ads` below.

### Ad Intelligence

```bash
# Active ad creatives for one app (slug comes from apps search results)
bash scripts/appkittie.sh ads --appSlug headspace-meditation-sleep --status active --limit 10

# Video ads across a category
bash scripts/appkittie.sh ads --categories "Health & Fitness" --mediaType video --limit 10

# Full detail for one creative
bash scripts/appkittie.sh ad --id meta_ad_123
```

### User Reviews

```bash
# Recent reviews - pain points, feature requests, app ideas (1 credit/review!)
bash scripts/appkittie.sh reviews --id 1234567890 --maxReviews 50

# Next page: pass the response's nextOffset
bash scripts/appkittie.sh reviews --id 1234567890 --maxReviews 50 --offset 50
```

### ASO Keywords

```bash
# Single keyword: popularity, difficulty, traffic score, top-ranked apps
bash scripts/appkittie.sh keyword --keyword "sleep tracker" --country US

# Batch (max 10 per call), ranked by opportunity
bash scripts/appkittie.sh keywords --keywords "meditation,sleep tracker,mindfulness,breathing exercises" --country US
```

### Global Flags

```bash
# Raw JSON (skip jq formatting)
bash scripts/appkittie.sh apps --sortBy trending --limit 5 --raw

# Override the API key
bash scripts/appkittie.sh apps --search fitness --key OTHER_KEY
```

## Pagination

List responses include `pagination.nextCursor` and `pagination.totalCount`. Pass `--cursor <nextCursor>` to fetch the next page; `null` means end of results. Each page costs credits per row - only paginate when the first page genuinely isn't enough.

## Error Handling

| HTTP | Meaning | Action |
|------|---------|--------|
| 400 | Bad input | Inspect `details` in the body, fix params |
| 401 | Missing/invalid key | Check `APPKITTIE_API_KEY` is set. Do NOT retry with different parameters - the key itself is bad; report it and fall back |
| 402 | Out of credits | **Stop retrying.** Report the balance is exhausted |
| 404 | Unknown app id | Verify the id via `apps` search |
| 429 | Rate limited | Wait for `X-RateLimit-Reset`, then retry once |
| 500 / 503 | Server fault / search backend down | Retry once after a pause, then fall back |

If the balance is below `limit` on an `apps` call, the API silently trims the page; fewer rows than requested is not an error.

## Output Shaping

Never dump raw JSON at the user. Synthesize short insight summaries:

- **Lead with the takeaway** in 1-2 sentences ("Sleep apps are top-heavy: the #1 earns ~10x the #5").
- **Compact table** for the data: app, developer, rating, reviews, downloads/mo, revenue/mo, growth.
- **3-5 bullet insights**: revenue concentration, growth patterns, ad-spend signals, gaps for new entrants.
- **Suggest the next call**: detail on a standout app, keyword scoring on terms that surfaced.
- Estimates are modeled, not exact - present revenue/download figures as approximations ("~$40K/mo"), and note the window (trailing 30d unless stated otherwise).

## Raw API Fallback

For edge cases the wrapper doesn't cover, call the API directly:

```bash
curl -sS "https://www.appkittie.com.proxy.chorus.com/api/v1/apps?search=fitness&limit=5" \
  -H "Authorization: Bearer ${APPKITTIE_API_KEY}" | jq .
```

All endpoints accept the same auth header; success bodies use a top-level `data`.

## References

- [references/api-reference.md](references/api-reference.md) - Complete filter matrix for `/apps`, response field tables, keyword payloads, credits, rate-limit headers
- [AppKittie Documentation](https://www.appkittie.com/docs) - Official docs
