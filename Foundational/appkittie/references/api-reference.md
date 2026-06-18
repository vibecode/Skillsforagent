# AppKittie API Reference

Base URL: `https://www.appkittie.com.proxy.chorus.com/api/v1`
Auth: `Authorization: Bearer ${APPKITTIE_API_KEY}` header on every request.
Override the proxy host with `APPKITTIE_BASE_URL` (host only; the wrapper appends `/api/v1`).

## Routes

| Route | Verb | Role | Credits |
|-------|------|------|---------|
| `/apps` | GET | Search / filter apps | 1 per app in the payload |
| `/apps/:appId` | GET | Full detail for one app | 1 per request |
| `/ads` | GET | Search / filter ad creatives | 1 per ad in the payload |
| `/ads/:adId` | GET | Full detail for one ad creative | 1 per request |
| `/keywords/difficulty` | GET | Single keyword score | 10 per request |
| `/keywords/difficulty` | POST | Batch keywords (max 10) | 10 per keyword with data |
| `/reviews` | POST | Fetch user reviews for an app | 1 per review returned |

## `GET /apps` - Filter Parameters

All filters are AND-combined.

| Group | Parameters | Notes |
|-------|------------|-------|
| Text | `search` | Matches title, developer, description |
| Categories | `categories`, `excludedCategories` | Comma-separated category names, e.g. `Health & Fitness` |
| Downloads | `minDownloads`, `maxDownloads` | Monthly estimates; lifetime min/max also available |
| Revenue | `minRevenue`, `maxRevenue` | Monthly USD estimates; lifetime min/max also available |
| Ratings | `minRating`, `maxRating` | 0-5 |
| Reviews | `minReviews`, `maxReviews` | Review counts |
| Price | `priceType` (`all` \| `free` \| `paid`), `minPrice`, `maxPrice` | |
| Growth | `growthPeriod` (`7d`, `14d`, `30d`, `60d`, `90d`), `growthMetric` (`reviews`) | Combine with `sortBy=growth&sortOrder=desc` for top growers |
| Signals | `hasMetaAds`, `hasAppleAds`, `hasCreators`, `hasEmails`, `hasWebsite` | Boolean |
| Content | `contentRating`, `languages`, `developer` | |
| Time | `releasedAfter`, `updatedAfter` | Unix seconds |
| Sort | `sortBy`, `sortOrder` (`asc` \| `desc`) | |
| Paging | `limit`, `cursor` | `limit` controls credits spent |

### `sortBy` values

`growth`, `rating`, `reviews`, `updated`, `released`, `downloads`, `revenue`, `trending`, `newest`

## Response Shapes

Success bodies use a top-level `data`. Lists add cursor pagination:

```json
{
  "data": [{ "title": "Calm", "score": 4.8, "downloads": 85000 }],
  "pagination": { "nextCursor": 50, "totalCount": 12450 }
}
```

Request the next page with `cursor=<nextCursor>`. `null` means end of results.

### List row fields

Title, icon, developer, category, rating, review count, download estimate, revenue estimate (trailing 30d), multi-window growth, release/update timestamps.

### Detail fields (`GET /apps/:appId`)

Everything in a list row plus:

- Description, screenshots, version history
- IAP catalog (products, pricing)
- Creator/influencer deals, contact hints, socials, hiring flags
- Historical series: rank, reviews, revenue, downloads

Ad creatives are NOT embedded in app detail - fetch them with `GET /ads?appSlug=<slug>`.

## `GET /ads` - Filter Parameters

| Group | Parameters | Notes |
|-------|------------|-------|
| Text | `search`, `textSearchFields` | Fields: `creative_text`, `title`, `body`, `cta_text`, `page_name`, `developer`, `app_title`, `category` |
| Source | `adSource` (`all` \| `meta` \| `google`), `mediaType` (`all` \| `image` \| `video`), `status` (`all` \| `active` \| `inactive`) | |
| App | `appSlug`, `developer`, `categories`, `excludedCategories` | `appSlug` = ads for one app |
| Reach | `countries`, `excludedCountries`, `adLanguages`, `excludedAdLanguages`, `surfaces`, `excludedSurfaces` | |
| Time | `startedAfter`, `startedBefore`, `endedAfter`, `endedBefore` | Unix seconds |
| App size | `minAppDownloads`, `maxAppDownloads` | Advertised app monthly downloads |
| Sort | `sortBy` (`start_date`, `end_date`, `app_downloads`, `app_revenue`, `app_released_timestamp`, `app_updated_timestamp`), `sortOrder` | |
| Paging | `limit` (1-100), `cursor` | |

Rows carry `ad_doc_id`, `ad_source`, `type`, `src`/`poster` asset URLs, creative copy, `is_active`, dates, and the advertised app. `GET /ads/:adId` returns the same plus an embedded `app` object.

## `POST /reviews` - Body Parameters

| Field | Required | Notes |
|-------|----------|-------|
| `appId` | yes | Numeric App Store id (or Google Play package name) |
| `source` | no | `apple_mobile` (default) \| `google_mobile`; inferred from `appId` |
| `country` | no | Storefront code, default `US` |
| `maxReviews` | no | 1-300, default 100 - **1 credit per review returned** |
| `offset` | no | Pagination; response `nextOffset` feeds the next call (`null` = end) |

Rows carry `id`, `rating`, `title`, `body`, `reviewerNickname`, `date`, `country`.

### Keyword fields

- `popularity` (0-100) and `difficulty` (0-100)
- Competing app count
- Traffic score (0-100)
- Leaderboard snippet per keyword: title, icon, reviews, score, rank

## Keyword Requests

Single (GET):

```bash
curl -sS "https://www.appkittie.com.proxy.chorus.com/api/v1/keywords/difficulty?keyword=sleep%20tracker&country=US" \
  -H "Authorization: Bearer ${APPKITTIE_API_KEY}"
```

Batch (POST, max 10 keywords, duplicates removed before charge):

```bash
curl -sS -X POST "https://www.appkittie.com.proxy.chorus.com/api/v1/keywords/difficulty" \
  -H "Authorization: Bearer ${APPKITTIE_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"keywords":["meditation","sleep tracker","mindfulness"],"country":"US"}'
```

`country` is a two-letter storefront code (e.g. `US`, `GB`, `DE`).

## Credits & Rate-Limit Headers

| Header | Meaning |
|--------|---------|
| `X-Credits-Used` | Credits spent by this call |
| `X-Credits-Remaining` | Balance left |
| `X-RateLimit-Limit` | Ceiling for the 60s sliding window |
| `X-RateLimit-Remaining` | Calls left in the window |
| `X-RateLimit-Reset` | Unix time when the window rolls |

If the balance is below `limit` on an `/apps` call, the API trims the page instead of erroring.

## Errors

JSON body includes `error`; validation issues add per-field `details`.

| HTTP | Situation |
|------|-----------|
| 400 | Bad input - inspect `details` |
| 401 | Missing or invalid key |
| 402 | Out of credits |
| 404 | Unknown app |
| 429 | Rate limited - body includes reset timing |
| 500 | Server fault |
| 503 | Search backend unavailable |
