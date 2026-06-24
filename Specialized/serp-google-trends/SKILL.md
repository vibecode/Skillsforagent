---
name: serp-google-trends
display_name: Google Trends
description: >
  Specialized skill for Google Trends workflows via SerpApi — interest over time, query
  comparison, regional interest, related queries/topics, real-time trending searches, and
  category-filtered trend analysis. Use when: (1) measuring search interest in a query over
  time, (2) comparing search interest between up to 5 queries, (3) mapping regional or
  city-level interest (GEO_MAP / GEO_MAP_0), (4) discovering related queries and rising
  searches for a topic, (5) finding related topics for content or SEO research,
  (6) monitoring real-time trending searches in a country (trending now),
  (7) filtering trends by category (e.g., Technology, Health, Finance, Games),
  (8) comparing trend interest across Google properties (Web, Images, News, Shopping, YouTube),
  (9) building seasonality or demand forecasting reports, (10) any task involving Google
  Trends data. This skill builds on the foundational serpapi skill for all API details.
dependencies:
  - serpapi
metadata: {"openclaw": {"emoji": "📈"}}
---

# Google Trends Workflows

Search interest measurement, regional analysis, related discovery, and real-time trending via SerpApi's Google Trends engines. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engines: `google_trends`, `google_trends_trending_now`)

## Core Concepts

### Engines

| Engine | Purpose |
|--------|---------|
| `google_trends` | Interest over time, geographic breakdown, related queries/topics for one or more search terms |
| `google_trends_trending_now` | Real-time trending searches in a country (replaces the old "daily trends") |

### Data Types (`data_type`)

The `google_trends` engine returns different response shapes depending on `data_type`:

| Value | Returns | Query Limit |
|-------|---------|-------------|
| `TIMESERIES` (default) | Interest over time | Up to 5 queries (comma-separated) |
| `GEO_MAP` | Regional comparison across queries | Multiple queries (≥2) |
| `GEO_MAP_0` | Interest by region for a single query | 1 query |
| `RELATED_TOPICS` | Top + Rising related topics | 1 query |
| `RELATED_QUERIES` | Top + Rising related search queries | 1 query |

### Interest Scores (0-100, relative)

Google Trends values are **always relative**, not absolute search counts:
- `100` — Peak popularity for the query within the selected time/region.
- `50` — Half the peak popularity.
- `0` — Insufficient data (not "no searches").

When comparing queries, the score is relative to the **highest single point across all queries** combined. A query at `30` is not "30% interest" — it's 30% of the busiest moment in the comparison.

### Rising vs Top

`RELATED_QUERIES` and `RELATED_TOPICS` each return two buckets:
- **`top`** — Most popular all-time within the period. Values are relative (0-100).
- **`rising`** — Fastest-growing. Values are **percent change** (e.g., `+450%`) or the literal string `"Breakout"` (>5000% growth — Google can't compute a precise number).

**`Breakout`** is the strongest possible signal. Surface these prominently.

### Date Ranges (`date`)

| Preset | Period |
|--------|--------|
| `now 1-H` | Past hour |
| `now 4-H` | Past 4 hours |
| `now 1-d` | Past day |
| `now 7-d` | Past 7 days |
| `today 1-m` | Past 30 days |
| `today 3-m` | Past 90 days |
| `today 12-m` | Past 12 months (default) |
| `today 5-y` | Past 5 years |
| `all` | 2004 → present |

**Custom range:** `YYYY-MM-DD YYYY-MM-DD` (e.g., `2024-01-01 2024-12-31`)
**Weekly with hours:** `YYYY-MM-DDThh YYYY-MM-DDThh`

**Resolution rule of thumb:**
- Hourly data → ranges ≤ 7 days
- Daily data → ranges ≤ 90 days
- Weekly data → ranges ≤ ~5 years
- Monthly data → `all`

### Geo Targeting

- `geo` — Country (e.g., `US`, `GB`, `JP`, `IN`) or subregion code (e.g., `US-CA` for California, `US-NY-501` for NYC DMA). Omit for **Worldwide**.
- `region` — Granularity for `GEO_MAP` / `GEO_MAP_0`:
  - `COUNTRY` — Country level (worldwide queries)
  - `REGION` — Subregion (e.g., US states)
  - `DMA` — Designated Market Area (US metros)
  - `CITY` — City level

### Property Filter (`gprop`)

Restrict trends to a Google property:

| Value | Property |
|-------|----------|
| _(empty / unset)_ | Web Search (default) |
| `images` | Google Images |
| `news` | Google News |
| `froogle` | Google Shopping |
| `youtube` | YouTube |

Useful for comparing demand intent (e.g., YouTube interest for tutorials vs Web for general research).

### Categories (`cat`)

Filter by Google Trends category ID. Default `0` = All categories. Common ones:

| ID | Category |
|----|----------|
| `0` | All |
| `3` | Arts & Entertainment |
| `5` | Computers & Electronics |
| `7` | Finance |
| `8` | Games |
| `12` | Business & Industrial |
| `16` | News |
| `20` | Online Communities |
| `45` | Health |
| `47` | Autos & Vehicles |
| `71` | Food & Drink |
| `174` | Travel |
| `299` | Sports |

Category filtering disambiguates terms (e.g., `q=jaguar&cat=47` for the car, not the cat).

### Timezone (`tz`)

Minutes offset from UTC, range `-1439` to `1439`. Default `420` (PDT). Set this for accurate hourly/daily bucketing in the user's locale.
- `-540` — Tokyo (UTC+9)
- `0` — UTC
- `300` — EDT (UTC-5)
- `420` — PDT (UTC-7)

## Workflows

### 1. Interest Over Time (Single Query)

Use the **serpapi** skill's wrapper script with engine `google_trends`. `data_type=TIMESERIES` is the default.

**Key parameters:**
- `q` — Search term (or encoded Topic ID like `/m/0dgw9r`)
- `date` — Preset or custom range
- `geo` — Country/region (omit for Worldwide)
- `cat` — Category filter (optional, disambiguates terms)
- `gprop` — Property filter (optional)
- `tz` — Timezone offset in minutes

**Response (`TIMESERIES`):**
- `interest_over_time.timeline_data[]` — Each entry: `{ date, timestamp, values: [{ query, value, extracted_value }] }`
- `interest_over_time.averages[]` — Average per query across the period

**Presentation pattern:**
1. Plot or describe the trend curve (rising, falling, seasonal, spiky).
2. Call out peak date(s) and any obvious events.
3. Report the average value and current vs peak ratio.

### 2. Comparing Up to 5 Queries

Comma-separate up to **5 queries** in `q`. Example: `q=chatgpt,claude,gemini,perplexity,copilot`.

All values are normalized to the single highest point across all 5 queries, so direct comparison is meaningful.

**Presentation pattern:**
```
📈 Interest Comparison — [Period], [Geo]

| Query       | Avg | Peak | Peak Date    |
|-------------|-----|------|--------------|
| chatgpt     | 87  | 100  | 2024-11-15   |
| claude      | 12  | 18   | 2024-12-02   |
| gemini      | 24  | 41   | 2024-11-22   |
| perplexity  | 8   | 14   | 2024-12-10   |
| copilot     | 19  | 31   | 2024-10-08   |

🏆 Leader: chatgpt (7x next competitor)
📈 Fastest riser: claude (+62% over period)
```

**Tip:** Order queries by expected popularity descending — easier to read in the response array order.

### 3. Regional Interest (Single Query — GEO_MAP_0)

Set `data_type=GEO_MAP_0` with a single `q`.

**Response:**
- `interest_by_region[]` — Each entry: `{ location, max_value_index, value, extracted_value }`. Sorted by interest.

**Use `region`** to control granularity:
- Worldwide query + `region=COUNTRY` → top countries by interest
- `geo=US` + `region=REGION` → top US states
- `geo=US` + `region=DMA` → top US metros
- `geo=US-CA` + `region=CITY` → top California cities

Add `include_low_search_volume=true` if you want all regions returned (otherwise low-volume regions are dropped).

### 4. Regional Comparison (Multiple Queries — GEO_MAP)

Set `data_type=GEO_MAP` with 2-5 queries.

**Response:**
- `compared_breakdown_by_region[]` — Each entry: `{ location, values: [{ query, value, extracted_value }] }`. Shows which query is more popular in each region.

**Use case:** "Is React more searched than Vue in each US state?" or "Which countries prefer Pepsi over Coke?"

**Presentation pattern:**
```
🗺️ Regional Preference — [Query A] vs [Query B]

[Query A] dominates: [list of regions, score gap]
[Query B] dominates: [list of regions, score gap]
Tied/Close: [regions with <10 point gap]
```

### 5. Related Queries (Top + Rising)

Set `data_type=RELATED_QUERIES` with a single `q`.

**Response:**
- `related_queries.top[]` — Each: `{ query, value, extracted_value, link, serpapi_link }`. Value is 0-100 relative.
- `related_queries.rising[]` — Each: `{ query, value, extracted_value, link, serpapi_link }`. Value is percent growth or `"Breakout"`.

**Surface `Breakout` queries first** — they signal emerging interest worth investigating.

**Presentation pattern:**
```
🔍 Related Queries for "[query]"

🚀 Rising (fastest growing):
   • [query 1] — Breakout 🔥
   • [query 2] — +850%
   • [query 3] — +320%

⭐ Top (most searched):
   • [query 1] (100)
   • [query 2] (78)
   • [query 3] (54)
```

**SEO/content use:** Rising queries reveal new angles before competitors catch on. Top queries reveal the established demand surface.

### 6. Related Topics

Set `data_type=RELATED_TOPICS` with a single `q`. Same structure as `RELATED_QUERIES` but each entry is a **Topic** (a disambiguated entity):

- `related_topics.top[]` / `related_topics.rising[]` — Each: `{ topic: { value (topic id), title, type }, value, extracted_value, link, serpapi_link }`

**Why topics matter:** Topics group multiple query variations (e.g., "iPhone 15", "iphone15", "iphone 15 pro") into one entity. Use topic IDs in follow-up queries for cleaner data.

### 7. Real-Time Trending Searches (Trending Now)

Use the `google_trends_trending_now` engine for live trending topics.

**Key parameters:**
- `geo` — Country code (required; default `US`)
- `hours` — `4`, `24` (default), `48`, or `168` (7 days)
- `category_id` — Optional filter (e.g., `6` Games, `18` Technology)
- `only_active` — `true` to limit to currently active trends
- `hl` — Language

**Response:**
- `trending_searches[]` — Each entry includes:
  - `query` — The trending term
  - `start_timestamp` / `end_timestamp` — Active window
  - `active` — Boolean (still trending right now?)
  - `search_volume` — Estimated total searches
  - `increase_percentage` — Growth metric
  - `categories[]` — `{ id, name }` tags
  - `trend_breakdown[]` — Related query suggestions
  - `serpapi_google_trends_link` — Link to drill into timeseries
  - `serpapi_news_link` — Associated news SERP

**Presentation pattern:**
```
🔥 Trending Now in [Geo] — last [hours]h

1. [query]  +[N]%  ([search_volume] searches)
   📰 [news headline if available]
   Categories: [list]
2. [query]  +[N]%  ...
```

**Drill-down pattern:** When a user asks "why is X trending?", follow up with `google_trends` `RELATED_QUERIES` for context, or hit the `serpapi_news_link` for headlines.

### 8. Category-Filtered Trends

Use `cat` to scope `google_trends` results to a category. Disambiguates polysemous terms and surfaces niche trends.

**Examples:**
- `q=python&cat=5` — Python the language (Computers & Electronics), not the snake.
- `q=apple&cat=5` vs `q=apple&cat=71` — Apple Inc vs the fruit.
- `q=jordan&cat=299` — Michael Jordan / Air Jordan in Sports.

**For trending now:** Use `category_id` (different parameter name) on the `google_trends_trending_now` engine.

### 9. Property Comparison (Web vs YouTube vs News)

Run the same `q` multiple times with different `gprop` values to compare intent surfaces:

| Property | Reveals |
|----------|---------|
| _(web)_ | General research / purchase intent |
| `youtube` | Tutorial / entertainment demand |
| `news` | News-driven attention spikes |
| `images` | Visual reference / inspiration |
| `froogle` | Shopping intent |

**Presentation pattern:**
```
[Query] — Cross-Property Interest, [Period]
  Web:      avg 64, peak 100 on [date]
  YouTube:  avg 41, peak 78  on [date]
  News:     avg 12, peak 100 on [date]  ← news-driven spike
  Shopping: avg 28, peak 55  on [date]
```

### 10. Seasonality & Forecasting Setup

For seasonality, use `date=today 5-y` or `date=all` and look at the timeline.

**Pattern:**
1. Pull 5-year `TIMESERIES` for the query.
2. Bucket values by month or week.
3. Identify recurring peaks (e.g., "swimsuit" peaks every June; "tax software" every March-April).
4. Compare year-over-year peak heights to detect rising/declining trends.

## Parameter Quick Reference

| Goal | Parameter | Value |
|------|-----------|-------|
| Past 7 days | `date` | `now 7-d` |
| Past 12 months (default) | `date` | `today 12-m` |
| Custom range | `date` | `2024-01-01 2024-12-31` |
| Compare 5 queries | `q` | `a,b,c,d,e` |
| Regional map (single) | `data_type` | `GEO_MAP_0` |
| Regional map (compare) | `data_type` | `GEO_MAP` |
| Related queries | `data_type` | `RELATED_QUERIES` |
| US states only | `geo`, `region` | `US`, `REGION` |
| US metros | `geo`, `region` | `US`, `DMA` |
| YouTube interest | `gprop` | `youtube` |
| Shopping intent | `gprop` | `froogle` |
| News spikes | `gprop` | `news` |
| Disambiguate term | `cat` | category ID |
| Include sparse regions | `include_low_search_volume` | `true` |
| Tokyo timezone | `tz` | `-540` |

## Common Patterns

### "Is interest in X growing?"
1. `TIMESERIES`, `date=today 12-m` (or `today 5-y` for long view).
2. Compute first-quarter avg vs last-quarter avg.
3. Pull `RELATED_QUERIES` rising bucket to explain *why* it's growing.

### "Compare X vs Y vs Z"
1. `TIMESERIES` with `q=X,Y,Z`.
2. Report avg, peak, and current value for each.
3. Optionally add `GEO_MAP` to show which regions prefer which.

### "Where is X most popular?"
1. `GEO_MAP_0` with the appropriate `geo` and `region` granularity.
2. List top 10 locations with values.
3. If user wants city-level US, set `geo=US-<state>`, `region=CITY`.

### "What's trending right now in [country]?"
1. `google_trends_trending_now`, `geo=<country>`, `hours=24`, `only_active=true`.
2. Present top 10-20 with search_volume and growth.
3. Offer to drill into any with `RELATED_QUERIES` or news links.

### "Find content ideas for [topic]"
1. `RELATED_QUERIES` — focus on **rising** bucket and any `Breakout` items.
2. `RELATED_TOPICS` — for entity-level expansion.
3. Cross-check with `gprop=youtube` to see what's hot on video.

### "Is [brand] losing to [competitor]?"
1. `TIMESERIES` with both queries, `date=today 5-y`.
2. Look for crossover points (where the lines cross).
3. `GEO_MAP` to see where each is winning.
4. `RELATED_QUERIES` for each — rising terms hint at category shifts.

## Tips

- **Interest scores are relative, not absolute.** Always explain this when presenting. "Interest reached 100" means peak within the window, not "100 searches."
- **`Breakout` is gold.** When a related query shows `"Breakout"`, it grew >5000% — a strong leading indicator. Always surface these first.
- **Use Topic IDs over text** when you have them. `q=/m/0dgw9r` (a Topic ID) gives cleaner data than `q=javascript` because it covers all language variants and is disambiguated.
- **`geo` is case-sensitive** and uses ISO codes: `US` not `us`, `GB` not `UK`.
- **Worldwide queries** drop `geo` entirely — don't pass an empty string.
- **Short date ranges = higher resolution.** `now 7-d` returns hourly data; `today 12-m` returns weekly. Choose based on the question.
- **Comparison normalization** means one dominant query can flatten others to near-zero. If a query looks dead, re-run it alone to see its true shape.
- **Category disambiguation** matters: `q=apple` returns mixed signal. Use `cat=5` (Tech) or `cat=71` (Food) to clarify.
- **`include_low_search_volume=true`** is essential for niche queries — without it, most regions return empty.
- **Trending now is country-specific.** There is no worldwide trending now — always pass `geo`.
- **`only_active=true`** filters trending now to live trends, useful for "what's hot *right now*" vs "what was hot today."
- **Async for batch jobs.** When pulling many comparisons or regional maps in bulk, set `async=true` and poll later to avoid blocking.
- **`no_cache=true`** when timeliness matters (e.g., breaking news trends). Otherwise rely on cached responses for speed.
