---
name: serp-apple-app-store
display_name: Apple App Store
description: >
  Specialized skill for Apple App Store workflows via SerpApi — app search, product detail
  lookup, review collection, developer profiles, category browsing, and cross-market app
  research. Use when: (1) searching for iOS or macOS apps by keyword or term,
  (2) looking up full app detail pages (description, screenshots, version history,
  in-app purchases, privacy practices), (3) collecting App Store reviews for a specific
  app, (4) finding all apps published by a specific developer, (5) browsing apps by
  category or genre, (6) comparing app availability and ratings across country stores,
  (7) filtering explicit content for family-safe results, (8) analyzing app pricing,
  ratings, and version release cadence, (9) researching competitor apps for market
  positioning, (10) tracking app rankings or version updates over time, (11) any task
  involving the Apple App Store catalog or app metadata. This skill builds on the
  foundational serpapi skill for all API details.
dependencies:
  - serpapi
metadata: {"openclaw": {"emoji": "📱"}}
---

# Apple App Store Workflows

App search, product detail lookup, review collection, and developer/category research via SerpApi's Apple App Store engines. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engines: `apple_app_store`, `apple_product`, `apple_reviews`)

## Core Concepts

### Three Engines, One Catalog

The Apple App Store integration spans three related engines:

| Engine | Purpose | Required ID |
|--------|---------|-------------|
| `apple_app_store` | Search the store catalog by keyword or developer | `term` (query string) |
| `apple_product` | Fetch full detail for a single app | `product_id` (numeric ID) |
| `apple_reviews` | Page through user reviews for a single app | `product_id` (numeric ID) |

**Typical flow:** Search with `apple_app_store` → pick a result → look up details with `apple_product` → collect reviews with `apple_reviews`.

### Product ID

Every App Store app has a numeric `id` (e.g., `534220544`). This ID is:
- Returned as the `id` field on every `apple_app_store` organic result
- Visible in any App Store URL after `id=` (e.g., `apps.apple.com/us/app/.../id534220544`)
- The exact value to pass as `product_id` to `apple_product` and `apple_reviews`

### Country Stores

The `country` parameter (two-letter code, default `us`) selects which regional App Store to query. An app's availability, pricing, ratings, and review pool vary by country store.

| Code | Store |
|------|-------|
| `us` | United States (default) |
| `gb` / `uk` | United Kingdom |
| `ca` | Canada |
| `au` | Australia |
| `de` | Germany |
| `fr` | France |
| `jp` | Japan |
| `cn` | China |
| `kr` | South Korea |
| `in` | India |
| `br` | Brazil |
| `mx` | Mexico |
| `it` | Italy |
| `es` | Spain |
| `nl` | Netherlands |
| `ru` | Russia |

Any ISO 3166-1 alpha-2 country code is supported. Use `lang` (four-letter, e.g. `en-us`, `fr-fr`, `ja-jp`) for localized result text.

### Response Structure — `apple_app_store`

The search response returns `organic_results[]`, each entry containing:

- `position` — Result rank in the list
- `id` — Numeric App Store ID (use this for product/reviews lookups)
- `title` — App name
- `bundle_id` — Reverse-DNS bundle identifier (e.g., `com.apple.mobilesafari`)
- `version`, `release_note`, `minimum_os_version`, `release_date`
- `description` — Full marketing description
- `age_rating` — e.g., `4+`, `9+`, `12+`, `17+`
- `price` — `{type, amount, currency, symbol}` (free apps have `amount: 0`)
- `rating` — `{type, rating, count}` (overall average + count)
- `genres[]` — Each `{name, id, primary}` (the `primary` genre marks the main category)
- `developer` — `{name, id, link}`
- `size_in_bytes`, `supported_languages[]`, `supported_devices[]`
- `screenshots`, `logos` — Image URLs (multiple resolutions)
- `features[]`, `advisories[]` — Capabilities and content warnings
- `game_center_enabled`, `vpp_license`

### Response Structure — `apple_product`

A single, deeply detailed object covering:

- **Core:** `title`, `snippet`, `id`, `age_rating`, `description`, `logo`
- **Developer:** `developer.{name, link}`
- **Pricing:** `price`, `in_app_purchases[]`
- **Media:** `iphone_screenshots[]`, `ipad_screenshots[]` (device-specific)
- **Ratings:** `rating`, `rating_count`, `ratings_and_reviews` (star distribution + sample reviews)
- **Version history:** `version_history[]` — each `{version, release_notes, release_date}`
- **Privacy:** `privacy.{policy_link, data_categories[]}`
- **Information:** `information.{seller, size, category, compatibility, languages, copyright}`
- **Supports:** `supports[]` — Siri, Wallet, Family Sharing, Game Center, etc.
- **Featured in:** `featured_in[]` — App Store editorial placements
- **Related:** `more_by_this_developer[]`, `you_may_also_like[]`

### Response Structure — `apple_reviews`

- `search_information.{total_page_count, reviews_for_current_version, results_count}`
- `reviews[]` — Each `{position, id, title, text, rating, review_date, reviewed_version, author.{name, author_id}}`
- `serpapi_pagination.{current, next}`

**Note:** macOS reviews omit `id` and `author_id`. macOS reviews are always chronological; `sort` only affects iOS reviews.

## Workflows

### 1. App Search by Keyword

Use the **serpapi** wrapper script with the `apple_app_store` engine.

**Required:** `term` (search query)
**Common optional params:**

| Parameter | Purpose | Default |
|-----------|---------|---------|
| `country` | Regional store | `us` |
| `lang` | UI/result language | `en-us` |
| `num` | Results to return (max 200) | `10` |
| `device` | `desktop`, `mobile`, or `tablet` | `desktop` |
| `disallow_explicit` | Hide explicit content | `false` |
| `category_id` | Limit to a category/genre ID | — |

**Presentation pattern:** Top 5-10 results with name, developer, rating + count, price, primary genre, and a one-line description hook. Highlight free vs. paid and any 4.5+ standouts.

### 2. Developer Search (Apps by Developer)

Set `property=developer` to scope the search to developer names rather than app titles. The `term` then matches the developer name.

**Use cases:**
- "Show me all apps by Snowman" → `term=Snowman`, `property=developer`
- Auditing a publisher's catalog
- Discovering apps by a developer the user already trusts

**Tip:** Combine with `num=50+` to surface the full catalog. Sort the results by `rating.rating` or `release_date` in your presentation.

### 3. Category / Genre Browsing

Use `category_id` to constrain results to a specific App Store genre. Common IDs:

| Category | ID |
|----------|-----|
| Games | `6014` |
| Business | `6000` |
| Education | `6017` |
| Entertainment | `6016` |
| Finance | `6015` |
| Health & Fitness | `6013` |
| Lifestyle | `6012` |
| Music | `6011` |
| Photo & Video | `6008` |
| Productivity | `6007` |
| Social Networking | `6005` |
| Travel | `6003` |
| Utilities | `6002` |
| Weather | `6001` |
| Medical | `6020` |
| News | `6009` |

Genres are also returned on each result as `genres[]`. Use the `id` field from a known good result to discover other category IDs.

**Strategy:** Pair `category_id` with a broad `term` (e.g., `term=todo` + `category_id=6007`) to find category-leading apps for that keyword.

### 4. App Detail Lookup

Once you have a `product_id` (from a search result's `id`, or extracted from an App Store URL), use the `apple_product` engine.

**Required:** `product_id`
**Optional:** `country`, `type` (defaults to `app`)

**What you get that search doesn't include:**
- Full version history with per-version release notes
- iPhone vs. iPad screenshot sets
- Star distribution histogram + sample reviews
- Privacy data categories (linked-to-you, tracked, etc.)
- In-app purchase tiers and pricing
- `more_by_this_developer` and `you_may_also_like` cross-promo

**Presentation pattern for an app detail page:**
1. Header: title, developer, logo, overall rating + count, price, age rating
2. Description (truncate to 3-4 paragraphs unless asked for full)
3. What's New (latest entry from `version_history`)
4. Key info: size, languages, compatibility, in-app purchases
5. Privacy summary (data categories collected)
6. Screenshots reference (iPhone/iPad counts and links)
7. Related apps (`more_by_this_developer` and `you_may_also_like`)

### 5. Review Collection

Use the `apple_reviews` engine to page through reviews for a specific app.

**Required:** `product_id`
**Optional:**

| Parameter | Values | Notes |
|-----------|--------|-------|
| `country` | Two-letter | Reviews are per-store |
| `page` | Integer ≥ 1 | Default 1 |
| `sort` | `mostrecent`, `mosthelpful`, `mostfavorable`, `mostcritical` | iOS only; macOS is always chronological |

**Pagination strategy:**

| Reviews Count | Strategy |
|---------------|----------|
| Low volume (≤50) | Fetch first 2-3 pages |
| Medium (50-500) | Sample first 3 pages + a few mid + last; sort variants for breadth |
| High volume (500+) | Fetch first 2-3 pages of each sort variant (`mostrecent` + `mostcritical` + `mostfavorable`) |

**Sort selection guide:**
- `mostrecent` — Current sentiment, post-update reception
- `mosthelpful` — Most-upvoted, representative reviews
- `mostfavorable` — What fans love (positive themes)
- `mostcritical` — Pain points and complaints (negative themes)

**Tip:** Pull `mostfavorable` + `mostcritical` (3 pages each) to build a balanced positive/negative summary without exhaustive pagination.

### 6. Country-Specific Availability Check

To check whether an app exists, and at what price/rating, in different markets, run the same `apple_product` request varying `country`.

**Strategy:**
1. Identify the canonical `product_id` (typically the US ID)
2. Loop over target countries (`us`, `gb`, `de`, `jp`, ...)
3. For each, capture `price`, `rating`, `rating_count`, and `description` (often localized)
4. Note any country where the lookup returns no result — the app isn't available in that store

**Presentation pattern:**

```
📱 [App Name] — Market Availability

| Country | Price        | Rating | Reviews |
|---------|-------------|--------|---------|
| US      | Free        | 4.7    | 12,341  |
| UK      | £4.99       | 4.6    | 1,892   |
| DE      | €4,99       | 4.5    | 1,103   |
| JP      | ¥600        | 4.8    | 422     |
| BR      | Not available |     —  |    —   |
```

### 7. Competitor Comparison

Compare two or more apps side by side using `apple_product` for each.

**Strategy:**
1. Identify `product_id` for each app (search first if you only have names)
2. Fetch `apple_product` for each (same `country` for fair comparison)
3. Compare key dimensions: rating, rating count, price, IAPs, last update date, version cadence, supported devices, privacy posture

**Presentation pattern:**

```
📱 Comparison: [App A] vs [App B] vs [App C]

| Dimension       | App A      | App B      | App C      |
|----------------|-----------|-----------|-----------|
| Rating          | ⭐ 4.7     | ⭐ 4.3     | ⭐ 4.6     |
| Review count    | 12,341    | 8,902     | 24,118    |
| Price           | Free      | $2.99     | Free      |
| IAP range       | $1-$50    | None      | $1-$10    |
| Last updated    | 5 days ago| 6 mo ago  | 2 wk ago  |
| Size            | 84 MB     | 32 MB     | 121 MB    |
| Tracks user?    | Yes       | No        | Yes       |
```

### 8. App Market Research

Aggregate market intelligence across a category or topic.

**Strategy:**
1. Use `apple_app_store` with relevant `term` (or `term`+`category_id`) and `num=50+`
2. From results, extract: rating distribution, price distribution (free vs. paid), top developers, average rating among top 20, release-date spread
3. For the top 3-5 candidates, fetch `apple_product` for deeper metrics
4. For each, optionally sample `apple_reviews` to gauge recent sentiment

**What to surface:**
- Market structure: free vs paid mix, average rating, top developers
- Leaders by rating × count (volume-weighted quality)
- Recent activity: which top apps shipped updates in the last 30 days
- White space: low-competition genre IDs

### 9. Explicit Content Filtering

Set `disallow_explicit=true` whenever results may be presented to family or younger users. This excludes apps flagged as explicit at the store level.

**When to default to `disallow_explicit=true`:**
- The user mentions kids, family, school, classroom
- The query involves entertainment/media categories where explicit variants exist
- Building a public-facing recommender

## Filter Quick Reference

| Goal | Engine | Parameter | Value |
|------|--------|-----------|-------|
| Keyword search | `apple_app_store` | `term` | e.g., `meditation` |
| Search by developer name | `apple_app_store` | `property` | `developer` |
| Limit to a category | `apple_app_store` | `category_id` | e.g., `6014` (Games) |
| Hide explicit apps | `apple_app_store` | `disallow_explicit` | `true` |
| More results per page | `apple_app_store` | `num` | up to `200` |
| Target a non-US store | any | `country` | e.g., `jp`, `gb`, `de` |
| Localize result text | `apple_app_store` | `lang` | e.g., `fr-fr`, `ja-jp` |
| Mobile-shaped results | `apple_app_store` | `device` | `mobile` |
| Fetch full app detail | `apple_product` | `product_id` | numeric ID |
| Page through reviews | `apple_reviews` | `page` | integer |
| Sort reviews | `apple_reviews` | `sort` | `mostrecent`, `mosthelpful`, `mostfavorable`, `mostcritical` |

## Presenting Results

### Search Result Card

For each app in a search result list, present:

```
📱 [App Name] — [Developer]
   ⭐ [Rating] ([Review count]) | [Price or "Free"] | [Primary genre]
   [One-line description hook from `description`]
   ID: [product_id]
```

### App Detail Header

```
📱 [App Name]
   by [Developer]   ⭐ [Rating] ([Review count])
   [Price]  •  [Age rating]  •  [Size]  •  v[Version]
   Updated [days/weeks/months ago]

   [Description first paragraph]

   What's New (v[Version]):
   [release_notes from latest version_history entry]
```

### Review Summary Block

```
💬 [App Name] — Reviews Summary

⭐ [Avg rating] across [count] ratings
Star distribution: [from ratings_and_reviews if available]

Recent themes (from mostrecent):
- [theme 1]
- [theme 2]

Top complaints (from mostcritical):
- [complaint 1]
- [complaint 2]

Top praise (from mostfavorable):
- [praise 1]
- [praise 2]
```

## Common Patterns

### "Find me a [type] app"
1. Search `apple_app_store` with `term=[type]`, `disallow_explicit=true` if context warrants
2. Present top 5-7 with rating, price, and description hook
3. Offer to deep-dive on any with `apple_product`

### "Tell me about [app]"
1. Search with `term=[app name]`, take the top result's `id`
2. Fetch `apple_product` with that `product_id`
3. Present the App Detail Header + What's New + key info
4. Offer to pull reviews next

### "Why are people rating [app] poorly?"
1. Resolve `product_id` (search or URL)
2. Fetch `apple_reviews` with `sort=mostcritical`, pages 1-3
3. Identify recurring complaint themes
4. Cross-reference with latest `version_history` release notes — was a recent update blamed?

### "What other apps does [developer] make?"
1. `apple_app_store` with `term=[developer name]`, `property=developer`, `num=50`
2. Optionally also pull `apple_product` for one of their apps to see `more_by_this_developer`
3. Sort by rating × count to surface their hits

### "Compare [App A] and [App B] for [use case]"
1. Resolve both `product_id`s via search
2. `apple_product` for each (same `country`)
3. Side-by-side comparison table (see Workflow 7)
4. Optionally pull `mostcritical` reviews from each to expose trade-offs

### "Is [app] available in [country]?"
1. Get canonical `product_id` from US (or any) store
2. `apple_product` with `country=[target]`
3. If the call returns no result, the app isn't available there; otherwise report localized price and rating

### "What are the top [category] apps right now?"
1. `apple_app_store` with a representative `term` + `category_id` for the category, `num=50`
2. Sort returned results by `rating.count` × `rating.rating` (volume-weighted)
3. Present top 10 with the search card format

## Tips

- **Always preserve the `product_id`** when displaying search results — the user (or you) will want to deep-dive next.
- **Country matters.** Reviews, prices, and even availability differ across stores. Always be explicit about which `country` you queried.
- **`lang` ≠ `country`.** `country=jp` selects the Japan store; `lang=ja-jp` localizes the result text. You usually want them paired.
- **`property=developer` is the only special property mode** — pass it to search developer names instead of app titles.
- **Free apps still have a `price` object** — check `price.amount == 0` rather than relying on a missing field.
- **In-app purchases** only surface in `apple_product` (not in search results). For monetization research, you must do the detail lookup.
- **Version history is gold for trend analysis.** A monthly cadence signals an actively maintained app; gaps of 6+ months are a yellow flag.
- **Privacy block matters for B2B / enterprise recommendations.** The `privacy.data_categories` array reveals what's tracked, linked to user, or used for advertising.
- **iPad vs iPhone screenshots are separate fields** — if the user is on iPad, lead with `ipad_screenshots`.
- **macOS reviews don't accept `sort`.** Don't waste a call setting it.
- **`category_id` discovery:** if you don't know the right category ID, run one search without it, inspect `genres[].id` on relevant results, then re-search with the right ID for focused output.
- **Pagination is per-page, not per-result count** for reviews — use `page`, not `num`, on the `apple_reviews` engine.
- **`disallow_explicit` defaults to `false`.** Set it explicitly to `true` for family-safe contexts; don't assume.
- **App Store URLs are a fast `product_id` source** — the numeric value after `id=` in any `apps.apple.com/.../id######` URL is your `product_id`.
