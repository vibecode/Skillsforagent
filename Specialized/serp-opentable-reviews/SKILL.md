---
name: serp-opentable-reviews
description: >
  Specialized skill for OpenTable restaurant review workflows via SerpApi — review collection,
  sentiment analysis, rating breakdowns, restaurant comparison, trend analysis, and multi-market
  review monitoring. Use when: (1) collecting reviews for a specific restaurant on OpenTable,
  (2) analyzing restaurant ratings (overall, food, service, ambience, value, noise),
  (3) comparing reviews across multiple restaurants, (4) tracking review sentiment over time,
  (5) reading AI-generated review summaries, (6) monitoring international restaurant reviews
  across OpenTable domains, (7) building restaurant reputation reports, (8) extracting diner
  photos from reviews, (9) analyzing reviewer demographics and patterns, (10) any task
  involving OpenTable restaurant reviews. This skill builds on the foundational serpapi skill
  for all API details.
metadata: {"openclaw": {"emoji": "🍽️", "requires": {"env": ["SERPAPI_KEY"]}, "primaryEnv": "SERPAPI_KEY"}}
---

# OpenTable Review Workflows

Restaurant review collection, sentiment analysis, rating breakdowns, and reputation monitoring via SerpApi's OpenTable Reviews engine. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engine: `open_table_reviews`)

## Core Concepts

### Restaurant ID (rid)

Every OpenTable restaurant has an ID derived from its URL path. Given `https://www.opentable.com/r/nobu-palo-alto`, the `rid` is `nobu-palo-alto`.

**How to find rids:**
- From an OpenTable URL: extract the path after `/r/` (e.g., `r/central-park-boathouse-new-york-2` or just `nobu-palo-alto`)
- From Google search: search `site:opentable.com "restaurant name"` and extract from the URL
- The `rid` parameter accepts both formats — with or without the `r/` prefix

### Response Structure

A review query returns three key sections:

**`reviews_summary`** — Aggregate restaurant data:
- `reviews_count` — Total number of text reviews
- `ratings_count` — Total number of ratings (may differ from reviews_count)
- `ratings_summary` — Average scores:
  - `overall` — Overall rating (1-5 scale)
  - `food` — Food quality rating
  - `service` — Service rating
  - `ambience` — Ambience rating
  - `value` — Value for money rating
  - `noise` — Noise level (string: "Quiet", "Moderate", "Energetic", "Loud")
- `ratings[]` — Distribution by star count: `{ stars, count }` for 1-5
- `ai_summary` — AI-generated summary of guest sentiment (natural language paragraph)

**`reviews[]`** — Individual reviews (10 per page):
- `id` — Unique review ID
- `content` — Full review text
- `dined_at` — When the reviewer dined (ISO 8601)
- `submitted_at` — When the review was posted (ISO 8601)
- `user` — Reviewer info:
  - `name` — Display name
  - `number_of_reviews` — Reviewer's total review count
  - `location` — Reviewer's city
  - `avatar` — Profile photo URL
  - `vip` — Boolean, indicates VIP diner status
- `rating` — Per-review scores:
  - `overall`, `food`, `service`, `ambience`, `value` — 1-5 integer scores
  - `noise` — String noise level
- `images[]` — Diner photos (when attached):
  - `id`, `timestamp`
  - `variants[]` — Multiple sizes: `small`, `medium`, `xlarge`, `wideMedium`, `wideLarge`
- `response` — Restaurant's reply (when present):
  - `content` — Reply text
  - `date` — Reply date

**`search_information`** — Pagination context:
- `page` — Current page number
- `total_pages` — Total pages available

### Pagination

Results return 10 reviews per page. Use the `page` parameter to navigate:
- Page `1` (default) = first 10 reviews
- Increment `page` for subsequent results
- Check `search_information.total_pages` to know when to stop

### Localization

The `open_table_domain` parameter targets specific markets. Default is `opentable.com` (US).

| Domain | Market |
|--------|--------|
| `opentable.com` | United States |
| `opentable.co.uk` | United Kingdom |
| `opentable.ca` | Canada |
| `opentable.com.au` | Australia |
| `opentable.de` | Germany |
| `opentable.fr` | France |
| `opentable.es` | Spain |
| `opentable.it` | Italy |
| `opentable.jp` | Japan |
| `opentable.nl` | Netherlands |
| `opentable.ie` | Ireland |
| `opentable.hk` | Hong Kong |
| `opentable.sg` | Singapore |
| `opentable.ae` | UAE |
| `opentable.com.mx` | Mexico |
| `opentable.com.tw` | Taiwan |
| `opentable.co.th` | Thailand |

## Workflows

### 1. Basic Review Collection

Collect reviews for a single restaurant.

Use the **serpapi** skill's wrapper script with the `open_table_reviews` engine.

**Required:** `rid` (restaurant ID from URL)
**Optional:** `page` (default 1), `open_table_domain` (default `opentable.com`)

**Presentation pattern:**
1. Show `reviews_summary` — overall rating, rating breakdown, total reviews
2. Include the `ai_summary` as a quick overview
3. List 5-10 most relevant reviews with rating, date, and key excerpts
4. Note reviewer credibility (review count, VIP status)

### 2. Full Review Deep Dive

Collect all reviews for comprehensive analysis by paginating through all pages.

**Strategy:**
1. Fetch page 1 to get `reviews_summary` and `search_information.total_pages`
2. Paginate through pages (10 reviews per page)
3. For restaurants with hundreds of pages, sample strategically — first page, last page, and every Nth page rather than fetching all

**When to paginate fully vs sample:**

| Reviews Count | Strategy |
|---------------|----------|
| ≤50 (5 pages) | Fetch all |
| 51-200 (6-20 pages) | Fetch all or sample every 2nd page |
| 201-500 (21-50 pages) | Sample every 3rd-5th page |
| 500+ | Sample first 3 pages + last 3 pages + 5-10 evenly spaced |

### 3. Sentiment & Rating Analysis

Break down ratings to identify strengths and weaknesses.

**Step 1:** Fetch the `reviews_summary` for aggregate scores.

**Step 2:** Identify gaps between categories. For example:
- Food 4.8 but Value 3.5 → Great food, perceived as overpriced
- Service 4.9 but Ambience 3.2 → Great staff, poor atmosphere
- Overall 4.5 but Noise "Loud" → High quality but not for quiet dining

**Step 3:** Analyze the star distribution from `ratings[]`:
- Skewed to 5 stars → Consistently excellent
- Bimodal (many 5s and 1s) → Polarizing; look for patterns in complaints
- Normal distribution around 3-4 → Average with room for improvement

**Step 4:** Read individual reviews filtered by rating to understand *why*:
- Pull low-rated reviews (1-2 stars) to identify complaint themes
- Pull high-rated reviews (5 stars) to identify what delights guests

**Presentation pattern:**
```
🍽️ [Restaurant Name] — Rating Analysis

📊 Overall: ⭐ [X.X] ([N] ratings)
   Food:     [X.X] | Service:  [X.X]
   Ambience: [X.X] | Value:    [X.X]
   Noise: [Level]

📈 Distribution:
   ★★★★★ [count] ([%]) ████████████
   ★★★★☆ [count] ([%]) ██████
   ★★★☆☆ [count] ([%]) ███
   ★★☆☆☆ [count] ([%]) █
   ★☆☆☆☆ [count] ([%]) █

💡 AI Summary: "[ai_summary text]"

✅ Strengths: [top-rated categories]
⚠️ Weaknesses: [lowest-rated categories]
```

### 4. Restaurant Comparison

Compare two or more restaurants side by side.

**Strategy:**
1. Fetch reviews for each restaurant (page 1 is usually sufficient for summary data)
2. Extract `reviews_summary` from each
3. Compare ratings across all categories
4. Read 5-10 reviews from each to identify qualitative differences

**Presentation pattern:**
```
🍽️ Restaurant Comparison

| Category  | Restaurant A | Restaurant B | Restaurant C |
|-----------|-------------|-------------|-------------|
| Overall   | ⭐ 4.6       | ⭐ 4.2       | ⭐ 4.8       |
| Food      | 4.4          | 4.5          | 4.7          |
| Service   | 4.5          | 3.8          | 4.9          |
| Ambience  | 4.7          | 4.3          | 4.6          |
| Value     | 4.1          | 4.6          | 3.5          |
| Noise     | Moderate     | Energetic    | Quiet        |
| Reviews   | 1,662        | 834          | 2,105        |

🏆 Best Food: Restaurant C (4.7)
🏆 Best Value: Restaurant B (4.6)
🏆 Best Service: Restaurant C (4.9)
```

### 5. Review Trend Analysis

Track how a restaurant's quality changes over time.

**Strategy:**
1. Fetch recent reviews (pages 1-3) for current performance
2. Fetch older reviews (later pages) for historical comparison
3. Compare ratings and sentiment between time periods
4. Use `dined_at` and `submitted_at` timestamps to group reviews by month/quarter

**What to look for:**
- **Improving trend:** Recent reviews rate higher than older ones → restaurant getting better
- **Declining trend:** Recent reviews rate lower → possible quality or management issues
- **Consistent:** Ratings stable across time → reliable experience
- **Seasonal patterns:** Some restaurants vary by season (tourist areas, seasonal menus)

**Presentation pattern:**
```
📈 [Restaurant Name] — Review Trends

Recent (last 3 months):  ⭐ 4.7 avg (45 reviews)
Previous quarter:         ⭐ 4.3 avg (52 reviews)
6+ months ago:           ⭐ 4.1 avg (48 reviews)

📊 Trend: ↗️ Improving
   Food score up from 4.0 → 4.5
   Service consistently strong at 4.6
   Value perception improving (3.8 → 4.2)
```

### 6. Photo Collection

Extract diner-submitted photos from reviews.

**Strategy:**
1. Paginate through reviews
2. Filter reviews that have `images[]` populated
3. Collect the `xlarge` or `wideLarge` variant URLs for highest quality
4. Group photos by date or reviewer

**Use cases:**
- Building a visual gallery for restaurant research
- Assessing food presentation quality from real diner photos
- Comparing advertised vs actual food appearance

### 7. Multi-Market Monitoring

Monitor a restaurant brand across different OpenTable markets.

**Strategy:**
1. Identify the brand's `rid` on each domain (may differ per market)
2. Fetch reviews from each relevant `open_table_domain`
3. Compare ratings and sentiment across markets

**Example:** A chain restaurant may be `nobu-palo-alto` on `opentable.com` and have a different rid on `opentable.co.uk`.

**When to use:** Restaurant chains, hospitality groups, or franchises operating in multiple countries.

### 8. Reviewer Profile Analysis

Assess reviewer credibility and patterns.

**Key signals:**
- `number_of_reviews` — High count (50+) suggests experienced, possibly more critical diner
- `vip` — VIP status indicates frequent OpenTable user
- `location` — Local reviewers may have different expectations than tourists
- Review length and detail — Longer reviews often more nuanced

**Use cases:**
- Weight reviews by reviewer credibility for more accurate sentiment
- Identify if negative reviews come from inexperienced or experienced diners
- Detect patterns (e.g., tourists consistently rate ambience higher)

### 9. Restaurant Reputation Report

Comprehensive report combining multiple analyses.

**Template:**
1. **Overview** — Name, overall rating, total reviews, AI summary
2. **Rating Breakdown** — All categories with star distribution
3. **Strengths & Weaknesses** — Top and bottom categories, specific praise/complaint themes
4. **Recent Performance** — Last 30-60 days trend vs historical
5. **Sample Reviews** — 3 positive, 3 negative, with restaurant responses if any
6. **Photos** — Notable diner photos showing food and ambience
7. **Competitive Context** — If comparing, how this restaurant ranks vs competitors

## Common Patterns

### "What do people think of [Restaurant]?"
1. Fetch reviews (page 1)
2. Present AI summary, overall rating, and rating breakdown
3. Highlight 2-3 standout positive and negative reviews
4. Note noise level and value perception

### "Compare [Restaurant A] vs [Restaurant B] for a dinner"
1. Fetch reviews for both
2. Side-by-side rating comparison
3. Highlight what each excels at
4. Recommend based on the user's priorities (food quality, ambience, value, noise)

### "Is [Restaurant] worth the price?"
1. Fetch reviews focusing on the `value` rating
2. Compare overall vs value score — large gap means overpriced perception
3. Read reviews mentioning price, value, worth
4. Check if `ai_summary` mentions value

### "Has [Restaurant] gotten better or worse recently?"
1. Fetch pages 1-3 (recent) and pages near the end (older)
2. Compare average ratings by time period using `dined_at` timestamps
3. Look for patterns in recent complaints vs older ones
4. Check if restaurant is responding to reviews (engagement signal)

### "Find the best [cuisine] restaurant in [city]"
1. Use Google search or Google Maps to find OpenTable restaurants in the area
2. Collect rids from OpenTable URLs
3. Fetch reviews for top candidates
4. Compare and rank by relevant criteria

## Tips

- **AI summary is gold** — The `ai_summary` field distills hundreds of reviews into a concise paragraph. Always present it.
- **10 reviews per page** — Plan pagination accordingly. A restaurant with 1,662 reviews has ~166 pages.
- **VIP reviewers** — Reviews from VIP diners often carry more weight due to their dining frequency and experience.
- **Restaurant responses** — When present, responses indicate active management and care for guest feedback. Note their tone and helpfulness.
- **Noise as a filter** — Noise level isn't a 1-5 rating but a string ("Quiet", "Moderate", "Energetic", "Loud"). Useful for recommending date-night (quiet) vs group dining (energetic) spots.
- **Rating gaps reveal stories** — A restaurant with Food 4.8 / Value 3.2 tells a very different story than Food 3.5 / Value 4.8. Always look at the gaps.
- **Seasonal sampling** — For trend analysis, sample reviews from different times of year to account for seasonal menu changes or tourist influx.
- **Pagination cost** — Each page costs one SerpApi credit. For large review sets, use sampling strategies rather than exhaustive pagination.
- **International rids** — Restaurant IDs may differ across OpenTable domains. The same restaurant might have different rids on `opentable.com` vs `opentable.co.uk`.
