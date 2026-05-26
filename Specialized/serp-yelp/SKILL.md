---
name: serp-yelp
display_name: Yelp
description: >
  Specialized skill for Yelp workflows via SerpApi — local business search, business detail
  lookup, review collection, sentiment analysis, and multi-market monitoring. Use when:
  (1) searching for local businesses by keyword and location on Yelp, (2) filtering results
  by category, price range, attributes (open now, delivery, outdoor seating, etc.),
  (3) fetching full business details including hours, photos, menu, and amenities,
  (4) collecting reviews for a specific Yelp business with pagination, (5) sorting reviews
  by date, rating, or elite-reviewer status, (6) comparing competitors in the same category
  and area, (7) monitoring business reputation across multiple Yelp domains
  (yelp.com, yelp.ca, yelp.co.uk, etc.), (8) analyzing rating distributions and review
  sentiment, (9) extracting photo galleries and popular menu items, (10) building local
  market research reports, (11) any task involving Yelp business listings, reviews, or
  metadata. This skill builds on the foundational serpapi skill for all API details.
dependencies:
  - serpapi
metadata: {"openclaw": {"emoji": "⭐"}}
---

# Yelp Workflows

Local business search, business detail lookup, review collection, and reputation monitoring via SerpApi's Yelp engines. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engines: `yelp`, `yelp_place`, `yelp_reviews`)

## Core Concepts

### Three Engines

Yelp on SerpApi spans three engines, each for a different stage of research:

| Engine | Purpose | Required Input |
|--------|---------|---------------|
| `yelp` | Search businesses by keyword + location | `find_desc`, `find_loc` |
| `yelp_place` | Fetch full business detail page | `place_id` |
| `yelp_reviews` | Paginate all reviews for a business | `place_id` |

A typical flow is **search → place detail → reviews**: discover businesses with `yelp`, drill into one with `yelp_place`, then pull reviews with `yelp_reviews`.

### Place IDs

Every Yelp business has **two** unique IDs returned by the search engine:
- **Alias** (slug form, e.g., `nobu-palo-alto`) — Human-readable, derived from the Yelp URL `yelp.com/biz/<alias>`.
- **Encrypted ID** (e.g., `ED7A7vDdg8yLNKJTSVHHmg`) — Opaque token.

**Important:**
- `yelp_place` accepts **either** form.
- `yelp_reviews` accepts **only the encrypted ID** (first ID type). Pulling reviews from search results requires using the encrypted `place_ids[0]`, not the alias.

When you only have a Yelp URL, the slug after `/biz/` is the alias. To get the encrypted ID, run a search or `yelp_place` first and pluck it from the response.

### Pagination

Pagination differs across engines:

| Engine | Per Page | Param |
|--------|----------|-------|
| `yelp` | 10 results | `start` (0, 10, 20, …) |
| `yelp_reviews` | up to 49 | `start` (0, 49, 98, …) and `num` |

`yelp_reviews` is much more efficient per credit than OpenTable — up to 49 reviews per call versus 10 — so prefer larger `num` for full collection.

### Localization

The `yelp_domain` parameter targets specific Yelp markets. Default is `yelp.com` (US). Common domains:

| Domain | Market |
|--------|--------|
| `yelp.com` | United States |
| `yelp.ca` | Canada |
| `yelp.co.uk` | United Kingdom |
| `yelp.com.au` | Australia |
| `yelp.ie` | Ireland |
| `yelp.de` | Germany |
| `yelp.fr` | France |
| `yelp.es` | Spain |
| `yelp.it` | Italy |
| `yelp.nl` | Netherlands |
| `yelp.be` | Belgium |
| `yelp.ch` | Switzerland |
| `yelp.at` | Austria |
| `yelp.cz` | Czech Republic |
| `yelp.pl` | Poland |
| `yelp.no` / `yelp.se` / `yelp.dk` / `yelp.fi` | Nordics |
| `yelp.com.mx` / `yelp.com.br` / `yelp.com.ar` / `yelp.cl` / `yelp.com.pe` | Latin America |
| `yelp.com.sg` / `yelp.com.hk` / `yelp.com.tw` / `yelp.com.ph` | Asia |
| `yelp.com.tr` | Turkey |
| `yelp.co.nz` | New Zealand |

Place IDs are domain-specific. The same business may have different aliases on different domains.

### Filters (search engine)

**`cflt` — Category filter** (works alongside `find_desc`). Common values:
- `restaurants`, `food`, `bars`, `coffee`, `breakfast_brunch`, `hotels`, `shopping`, `nightlife`, `arts`, `active`, `auto`, `homeservices`, `beautysvc`, `health`, `pets`, `professional`, `localservices`

The `filters` block in the search response surfaces the exact `cflt` values available for the current query — use it to discover precise category tokens.

**`attrs` — Attribute / refinement filter.** Common values:

| Goal | `attrs` Value |
|------|---------------|
| $ price | `RestaurantsPriceRange2.1` |
| $$ price | `RestaurantsPriceRange2.2` |
| $$$ price | `RestaurantsPriceRange2.3` |
| $$$$ price | `RestaurantsPriceRange2.4` |
| Outdoor seating | `OutdoorSeating` |
| Delivery | `RestaurantsDelivery` |
| Takeout | `RestaurantsTakeOut` |
| Reservations | `RestaurantsReservations` |
| Open now | `open_now` |
| Live music | `Music.live` |
| Hot & new | `NewBusiness` |
| Offers a deal | `deals` |

Combine attributes with commas: `attrs=OutdoorSeating,RestaurantsDelivery,RestaurantsPriceRange2.2`.

**`sortby` — Result ordering:**

| Value | Effect |
|-------|--------|
| `recommended` (default) | Yelp's blended ranking |
| `rating` | Highest rated first |
| `review_count` | Most reviewed first |

**`l` — Location/radius filter.** Coordinate pairs set the map radius, or a neighborhood id narrows to a specific area. The response `filters` block lists available `l` tokens for the searched city.

### Search response structure

The `yelp` engine returns:
- `search_metadata` — Request ID, status, timing.
- `filters` — Available `cflt`, `attrs`, `l`, and price options for the current query (use these to discover valid filter values).
- `organic_results[]` — Each entry includes:
  - `position`, `title`, `link` (Yelp business URL)
  - `place_ids[]` — `[encrypted_id, alias]` (use `place_ids[0]` for `yelp_reviews`)
  - `rating`, `reviews` (count), `price` (`$`–`$$$$`)
  - `categories[]`, `neighborhoods[]`, `phone`
  - `service_options` — Delivery/takeout/dine-in availability
  - `thumbnail`
- `ads_results[]` — Sponsored listings (similar fields).
- `pagination` / `serpapi_pagination` — Next-page tokens.

### Place response structure

The `yelp_place` engine returns `place_results` with:
- **Basics:** `name`, `place_ids[]`, `rating`, `reviews`, `price`, `is_claimed`, `categories[]`, `about`
- **Contact:** `phone`, `address`, `website`, `directions`, `cross_streets`, `neighborhoods`, `country`
- **Hours:** `operation_hours` (with `special_hours` for holidays) and `business_alert` (closure/relocation notices)
- **Media:** `images[]`, `see_all_images_link`, `ambiance` (categorized photo groups with highlights)
- **Menu:** `popular_items[]` (each with photo and review count). Pass `full_menu=true` to scrape the complete menu; `menu_name` selects when multiple exist.
- **Features:** `features[]` (delivery, takeout, reservations status), `health_provider` (compliance scores), `community_questions[]` with answers
- **Reviews preview:** `review_highlights[]` — common praised items/phrases distilled across reviews

### Reviews response structure

The `yelp_reviews` engine returns:
- `search_information.total_results` — Total review count
- `search_information.business` — Business name
- `reviews[]` — Each with:
  - `position`, `rating` (1-5)
  - `user` — `name`, `id`, `thumbnail`, `location`, plus `friend_count`, `photo_count`, `review_count`, and elite badges
  - `comment.text`, `comment.language`
  - `date` (ISO 8601)
  - `photos[]` (with optional captions)
  - `owner_replies[]` (business responses with owner info)
  - `feedback` — `useful`, `funny`, `cool` counts
- `serpapi_pagination.next` — URL for the next page

**Sort options (`sortby`):**

| Value | Effect |
|-------|--------|
| `relevance_desc` (default) | Yelp's relevance ranking |
| `date_desc` | Newest first |
| `date_asc` | Oldest first |
| `rating_desc` | Highest rated first |
| `rating_asc` | Lowest rated first |
| `elites_desc` | Elite reviewers first |

**Other useful params:**
- `rating` — Filter reviews to a specific star count (`5`, `4`, …) or comma list (`4,5`).
- `q` — Search within review text (e.g., `q=spicy` to find reviews mentioning "spicy").
- `not_recommended=true` — Yelp hides some reviews as "not recommended"; this flag surfaces them.
- `hl` — Two-letter language code to filter reviews by language.

## Workflows

### 1. Local Business Search

Discover businesses for a keyword + location.

Use the **serpapi** skill's wrapper script with the `yelp` engine.

**Required:** `find_desc` (query), `find_loc` (city / address / ZIP).
**Optional:** `cflt`, `attrs`, `sortby`, `start`, `yelp_domain`, `l`.

**Strategy:**
1. Start with a simple `find_desc` + `find_loc` to see what's available.
2. Inspect the `filters` block to find valid `cflt`, `attrs`, and `l` tokens.
3. Re-run with filters to narrow results (e.g., open-now sushi under $$).
4. Use `sortby=rating` for highest-rated, or `sortby=review_count` for most-popular.

**Presentation pattern:**
```
⭐ Top [N] [query] in [location]

1. [Business Name] — ⭐ [rating] ([review_count] reviews) · [price]
   [categories] · [neighborhood]
   📞 [phone] · [service_options]
   [Yelp link]

2. ...
```

### 2. Filtered Search (Open Now, Price, Features)

Combine `cflt` + `attrs` to express compound intent.

**Examples:**

| Intent | Params |
|--------|--------|
| Cheap eats with delivery | `cflt=restaurants`, `attrs=RestaurantsPriceRange2.1,RestaurantsDelivery` |
| $$ patio dining | `cflt=restaurants`, `attrs=RestaurantsPriceRange2.2,OutdoorSeating` |
| Open right now | `attrs=open_now` |
| Date-night fancy | `cflt=restaurants`, `attrs=RestaurantsPriceRange2.3,RestaurantsReservations` |
| Live music bars | `cflt=bars`, `attrs=Music.live` |

If a filter token returns no results, fetch a baseline search and read the `filters` block — Yelp may use a slightly different token for that market.

### 3. Business Detail Lookup

Pull the full profile for a specific business.

Use the `yelp_place` engine with the `place_id` (alias or encrypted ID).

**Presentation pattern:**
```
⭐ [Business Name]  ⭐ [rating] ([reviews] reviews) · [price]
   [categories] · [is_claimed ? "Verified" : ""]
   
📍 [address]
   [neighborhoods] · [cross_streets]
📞 [phone]
🌐 [website]

🕐 Hours
   Mon: [hours]
   ...
   [business_alert if present]

🔥 Popular Items
   - [item] ([photo/review counts])

💬 Review Highlights
   "[highlight phrase]" — mentioned in [N] reviews
```

**When to set `full_menu=true`:** Only if the user asks about menu details — it's a heavier scrape.

### 4. Full Review Collection

Paginate every review for a business.

**Required:** `place_id` (use the **encrypted** form — `place_ids[0]` from search/place results).

**Strategy:**
1. First call with `start=0`, `num=49` to get the first batch and `total_results`.
2. Compute number of pages: `ceil(total_results / 49)`.
3. Paginate by incrementing `start` by 49 each time (`0`, `49`, `98`, …).
4. For very large review sets, sample rather than fetch all.

**Sampling guide:**

| Reviews | Strategy |
|---------|----------|
| ≤200 (~4 pages) | Fetch all |
| 201-1,000 (5-21 pages) | Fetch all, or sample every 2nd-3rd page |
| 1,001-5,000 | Sample first 3 pages + last 2 + 5-10 evenly spaced |
| 5,000+ | Use `sortby` slices (newest 2 pages + highest 2 pages + lowest 2 pages) |

### 5. Sentiment & Rating Analysis

Build a sentiment picture from review aggregates.

**Step 1 — Pull review_highlights from `yelp_place`.** These are Yelp's pre-distilled praise themes — present them first.

**Step 2 — Sample reviews by sort to capture range:**
- `sortby=rating_desc` (2 pages) → what people love
- `sortby=rating_asc` (2 pages) → what people complain about
- `sortby=date_desc` (2 pages) → recent performance
- `sortby=elites_desc` (1 page) → most credible voices

**Step 3 — Build a rating distribution.** Use the `rating` filter to count reviews per star level:
- Run `rating=5`, `rating=4`, …, `rating=1` and capture `total_results` for each.

**Step 4 — Identify themes.** Cluster comments by frequent keywords (food, service, wait, price, ambiance).

**Presentation pattern:**
```
⭐ [Business Name] — Rating Analysis

📊 Overall: ⭐ [X.X] ([N] reviews) · [price]

📈 Distribution:
   ★★★★★ [count] ([%]) ████████████
   ★★★★☆ [count] ([%]) ██████
   ★★★☆☆ [count] ([%]) ███
   ★★☆☆☆ [count] ([%]) █
   ★☆☆☆☆ [count] ([%]) █

💬 Yelp Review Highlights
   • "[highlight]" — [N] reviews
   • "[highlight]" — [N] reviews

✅ Strengths: [themes from 5-star reviews]
⚠️ Complaints: [themes from 1-2 star reviews]
🕐 Recent trend: [improving / stable / declining]
```

### 6. Competitor Comparison

Compare businesses in the same category and area.

**Strategy:**
1. Run a `yelp` search with `cflt` + `find_loc` to find candidates.
2. For each top result, capture `rating`, `reviews`, `price`, and `categories` from `organic_results`.
3. Optionally pull `yelp_place` for each to get `review_highlights` and `features`.

**Presentation pattern:**
```
⭐ [Category] in [Location] — Top [N]

| Business | Rating | Reviews | Price | Notable |
|----------|--------|---------|-------|---------|
| A        | ⭐ 4.6  | 1,240   | $$    | Outdoor seating, Delivery |
| B        | ⭐ 4.4  | 3,011   | $$$   | Reservations |
| C        | ⭐ 4.8  | 412     | $$    | Hot & new |

🏆 Most loved: C (4.8)
🏆 Best value: A ($$ + 4.6)
🏆 Most established: B (3,011 reviews)
```

### 7. Multi-Market Monitoring

Track a brand across multiple Yelp domains.

**Strategy:**
1. For each market, search the brand name with `yelp_domain=yelp.<tld>` and `find_loc=<city in market>`.
2. Capture place IDs per market — they will differ.
3. Pull `yelp_place` or `yelp_reviews` per market to compare ratings and themes.

**Use case:** Chain restaurants, retail brands, or hospitality groups operating across countries.

### 8. Search Within Reviews

Find reviews mentioning a specific term.

Pass `q=<term>` to `yelp_reviews` to surface only reviews containing it. Combine with `rating` to filter further (e.g., `q=service rating=1,2` to find service complaints).

**Use cases:**
- "Do people complain about wait times?" → `q=wait`
- "Is the spicy ramen any good?" → `q=spicy rating=4,5`
- "Are there allergy mentions?" → `q=allergy`

### 9. Photo Gallery Extraction

Collect business and diner photos.

**Two sources:**
- `yelp_place.place_results.images[]` and `ambiance` — Business and curated photos with categories (food, interior, etc.).
- `yelp_reviews.reviews[].photos[]` — User-uploaded review photos with captions.

**Strategy:** Combine both for a complete gallery, deduping by URL. Filter `yelp_reviews` to `sortby=date_desc` to see the most recent visual evidence.

### 10. Elite Reviewer Analysis

Weight reviews by credibility.

**Strategy:**
1. Run `yelp_reviews` with `sortby=elites_desc`.
2. Look at `user.review_count`, `user.friend_count`, `user.photo_count` — high counts indicate experienced reviewers.
3. Read these reviews first when building reputation reports — they tend to be more detailed and balanced.

### 11. Non-Recommended Review Audit

Yelp's algorithm hides some reviews ("not recommended"). Set `not_recommended=true` on `yelp_reviews` to see them.

**Use case:** When public ratings look much better or worse than reality, the hidden pool can reveal review manipulation patterns (review bombing, fake 5-star bursts).

## Common Patterns

### "Find me the best [cuisine] in [city]"
1. `yelp` search with `find_desc=<cuisine>`, `find_loc=<city>`, `sortby=rating`.
2. Present top 5-10 with rating, review count, price, neighborhood.
3. Offer to pull full details on a chosen business.

### "What's open right now for [food] near me?"
1. `yelp` search with `find_desc=<food>`, `find_loc=<location>`, `attrs=open_now`.
2. Sort by `rating` or distance via `l`.
3. Highlight hours and `service_options` (delivery/takeout).

### "Tell me about [business name]"
1. Resolve to a `place_id` via `yelp` search (use the slug or encrypted ID from `place_ids`).
2. `yelp_place` for full profile.
3. Optionally `yelp_reviews` (page 1, `sortby=date_desc`) for recent sentiment.

### "Why are people unhappy with [business]?"
1. `yelp_reviews` with `sortby=rating_asc`, page 1-2.
2. Cluster complaints by theme (service, food, wait, price).
3. Cross-check with `q=<theme>` to see how widespread each issue is.

### "Compare [Business A] vs [Business B]"
1. Resolve both `place_id`s via search.
2. `yelp_place` for each — pull rating, reviews, price, features, highlights.
3. Side-by-side table; recommend based on user's priorities.

### "How has [business] been trending?"
1. `yelp_reviews` with `sortby=date_desc` for the most recent 2-3 pages.
2. `yelp_reviews` with `sortby=date_asc` skipped to a later `start` for older comparison.
3. Compare average ratings and complaint themes between time slices.

### "Find [category] competitors near [business]"
1. `yelp_place` on the target business to grab its `address`/`neighborhoods`.
2. `yelp` search with `cflt=<same category>`, `find_loc=<neighborhood or address>`.
3. Rank competitors by rating × review_count.

## Tips

- **Two IDs, different uses.** `yelp_place` accepts both alias and encrypted ID. `yelp_reviews` requires the **encrypted** ID — always pull `place_ids[0]` from search results, not the slug.
- **Inspect `filters` first.** The search response's `filters` block lists the valid `cflt`, `attrs`, and `l` tokens for the current market. Use it to discover precise filter values rather than guessing.
- **49 reviews per page** for `yelp_reviews` — much more efficient than other review engines. Always use `num=49` unless you need fewer.
- **Encrypted IDs travel with the URL.** From a Yelp URL alone you only get the alias. Run a search or `yelp_place` first to obtain the encrypted ID before calling `yelp_reviews`.
- **`review_highlights` is gold.** `yelp_place.review_highlights[]` distills hundreds of reviews into key phrases — always present these before raw review excerpts.
- **Elite reviews carry weight.** Yelp Elites are vetted, frequent reviewers — their feedback is generally more reliable. Use `sortby=elites_desc` for high-signal samples.
- **`is_claimed`** indicates whether the owner has claimed the business — unclaimed listings may have stale info.
- **`business_alert`** flags temporary closures or relocations — surface this prominently when present.
- **`not_recommended` reviews** are filtered out by default. Check them when assessing manipulation risk or when ratings look suspicious.
- **Domain-specific IDs.** A business has different `place_id`s on different Yelp domains. Search each domain separately for international monitoring.
- **`q` for review search** is cheap and powerful — use it to validate specific claims ("Does this place deliver on time?") rather than scrolling reviews.
- **Price uses `RestaurantsPriceRange2.N`** where `N` is 1 ($) through 4 ($$$$). The `.2` after `RestaurantsPriceRange` is part of the token, not a typo.
- **Pagination cost.** Each `yelp` page costs one credit (10 results); each `yelp_reviews` page costs one credit (up to 49 results). Prefer wider per-page reads to minimize credits.
