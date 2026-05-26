---
name: serp-google-shopping
display_name: Google Shopping
description: >
  Specialized skill for Google Shopping workflows via SerpApi — product search, price comparison,
  seller comparison, deal hunting, product detail lookup, and marketplace research. Use when:
  (1) searching for products by keyword on Google Shopping, (2) filtering products by price range,
  brand, condition, rating, or shipping, (3) comparing sellers for the same product, (4) tracking
  prices across queries or marketplaces, (5) looking up full product details with seller lists,
  reviews, and specs, (6) finding deals, sales, or discounted merchandise, (7) localizing shopping
  searches across countries (US, UK, DE, etc.), (8) building product recommendation reports,
  (9) extracting product ratings and review summaries, (10) researching small-business or
  free-shipping listings, (11) sorting results by price ascending/descending, (12) any task
  involving Google Shopping product data. This skill builds on the foundational serpapi skill
  for all API details.
dependencies:
  - serpapi
metadata: {"openclaw": {"emoji": "🛒"}}
---

# Google Shopping Workflows

Product search, price comparison, seller analysis, and deal hunting via SerpApi's Google Shopping engine. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engines: `google_shopping`, `google_immersive_product`, `google_product` [deprecated])

## Core Concepts

### Engines

| Engine | Purpose | Required Input |
|--------|---------|----------------|
| `google_shopping` | Product search by keyword | `q` |
| `google_immersive_product` | Full product detail with all sellers/reviews | `page_token` |
| `google_product` | (Deprecated by Google) Product detail | `product_id` |

**Always prefer `google_immersive_product`** for product detail lookups — `google_product` has been shut down by Google. Get the `page_token` from `immersive_product_page_token` on a shopping result.

### Response Structure

A `google_shopping` query returns these key sections:

**`shopping_results[]`** — Primary product listings. Each result has:
- `position` — Rank in results
- `title` — Product name
- `product_id` — Google catalog ID
- `product_link` — Google Shopping URL
- `source` — Merchant name (e.g., "Amazon", "Best Buy")
- `price` / `extracted_price` — Current price (string + numeric)
- `old_price` / `extracted_old_price` — Original price if discounted
- `rating` — Average score (1-5)
- `reviews` — Total review count
- `snippet` — Short review summary
- `delivery` — Shipping info (e.g., "Free delivery by Tue, Mar 4")
- `tag` / `extensions` — Badges (e.g., "SALE", "20% OFF")
- `thumbnail` — Product image URL
- `immersive_product_page_token` — Token for detail lookup
- `serpapi_immersive_product_api` — Pre-formatted URL for detail call

**`inline_shopping_results[]`** — Prominent top listings (same fields as `shopping_results`).

**`categorized_shopping_results[]`** — Products grouped by category (e.g., "Ergonomic office chairs", "Standing desks").

**`filters[]`** — Refinement options Google offers (e.g., "On sale", "Free shipping", "Get today") with encoded `shoprs` tokens.

**`carousel_filters[]`** — Quick-access clickable filter tokens.

**`serpapi_pagination.next`** — URL for next page of results.

### Pagination

Results return in pages of 60. Use `start` parameter:
- `start=0` (default) → first 60 results
- `start=60` → next 60
- `start=120` → next 60

**Recommended:** Follow `serpapi_pagination.next` rather than computing offsets manually.

### Localization

Use `gl` (country) and `hl` (language) to target marketplaces:

| `gl` | Market | `hl` Example |
|------|--------|--------------|
| `us` | United States | `en` |
| `uk` | United Kingdom | `en` |
| `de` | Germany | `de` |
| `fr` | France | `fr` |
| `es` | Spain | `es` |
| `it` | Italy | `it` |
| `jp` | Japan | `ja` |
| `ca` | Canada | `en` |
| `au` | Australia | `en` |
| `br` | Brazil | `pt` |
| `mx` | Mexico | `es` |
| `in` | India | `en` |

**Tip:** Google Shopping availability varies by region. Some queries return zero results in markets where Shopping isn't active.

## Workflows

### 1. Basic Product Search

Use the **serpapi** wrapper script with the `google_shopping` engine.

**Required:** `q` (search query)
**Common optional:**
- `gl` / `hl` — Localization
- `location` — Search origin point (city/region)
- `device` — `desktop` (default), `tablet`, `mobile`

**Example parameters:**
```
engine=google_shopping
q=wireless noise cancelling headphones
gl=us
hl=en
```

**What to present:** Top 5-10 products with title, price, source, rating, delivery, and link.

### 2. Price Range Filtering

Limit results to a budget window using `min_price` and `max_price`.

```
q=4k monitor
min_price=200
max_price=500
```

Both override any `shoprs`-embedded pricing filters. Either can be used alone.

**Use when:** User states a budget ("under $500", "between $200-$500").

### 3. Sort by Price

Use `sort_by`:
- `1` — Price ascending (cheapest first)
- `2` — Price descending (most expensive first)

```
q=mechanical keyboard
sort_by=1
```

Default sort is Google's relevance/popularity ranking. Use `sort_by=1` for "cheapest X" queries.

### 4. Deal & Sale Hunting

Multiple boolean filters target discounted listings:

| Filter | Effect |
|--------|--------|
| `on_sale=true` | Discounted items only |
| `free_shipping=true` | No-shipping-cost items only |
| `small_business=true` | Independent merchant listings only |

```
q=winter jacket
on_sale=true
free_shipping=true
```

**Watch for `old_price` / `extracted_old_price`** in results — non-null means the item is discounted. Compute `discount = (old_price - price) / old_price` to rank deals by percent off.

### 5. Brand / Condition / Rating Filters via `shoprs`

Google Shopping uses `shoprs` tokens for brand, condition, rating, and other refinements. These tokens are not memorizable — extract them from the `filters[]` response.

**Two-step pattern:**

1. Run initial query without `shoprs`. Inspect the `filters[]` array in the response to find tokens for available brands, conditions ("New", "Used", "Refurbished"), seller ratings, etc.
2. Re-query with `shoprs=<token>`. Combine multiple tokens using `||` separator.

```
# Step 1: discover available filters
q=iphone

# Step 2: apply selected filters (Apple brand + New condition)
q=iphone
shoprs=<brand_token>||<condition_token>
```

**Note:** `min_price`, `max_price`, and `sort_by` parameters supersede any pricing/sorting embedded in `shoprs`.

### 6. Product Detail Lookup (Sellers, Reviews, Specs)

Once a user picks a product from search results, fetch full detail using the `google_immersive_product` engine.

**Get the token:** Each `shopping_results[]` item includes `immersive_product_page_token`. Pass it as `page_token`.

```
engine=google_immersive_product
page_token=<immersive_product_page_token from shopping result>
```

**Optional:**
- `more_stores=true` — Up to 13 sellers instead of the default 3-5
- `next_page_token` — Paginate through additional sellers using `stores_next_page_token` from prior response

**Response highlights:**
- `title`, `brand`, `rating`, `reviews`, `price_range`, `thumbnails`
- `stores[]` — Each seller: name, logo, link, price, original_price, discount, payment_methods, details_and_offers, estimated_tax, shipping, total
- `ratings[]` — Star distribution (1-5 with counts)
- `user_reviews[]` — Individual reviews (title, text, rating, date)
- `critic_ratings[]` — Professional reviewer scores
- `about_the_product` — Description and spec features
- `top_insights[]` — Key points by aspect (e.g., "Picture Quality", "Battery Life")
- `variants[]` — Color, size, storage, capacity options (each with availability)
- `videos[]` — YouTube and platform videos
- `discussions_and_forums[]` — Reddit threads and community discussions
- `related_searches[]` — Suggested query refinements

**Presentation pattern:** Lead with title + average rating + price range. Then seller comparison table (sorted by total cost). Then top reviews. Then specs/variants.

### 7. Seller Comparison for the Same Product

Compare retailers selling the same product to find best price + reliability.

**Strategy:**
1. From a `google_shopping` query, identify the desired product (note its `immersive_product_page_token`)
2. Call `google_immersive_product` with `more_stores=true`
3. Sort `stores[]` by `total` (price + tax + shipping) ascending
4. Surface payment methods, return policy, and any discount badge

**Presentation pattern:**
```
🛒 [Product Title] — Seller Comparison

| Seller          | Price   | Shipping | Total   | Notes                        |
|-----------------|---------|----------|---------|------------------------------|
| Amazon          | $249.99 | Free     | $249.99 | Prime, 30-day returns        |
| Best Buy        | $239.99 | $9.99    | $249.98 | Free pickup available        |
| Walmart         | $244.00 | Free     | $244.00 | ⭐ Best total                |
| Target          | $259.99 | Free     | $259.99 | RedCard 5% off               |
| B&H Photo       | $229.00 | $14.99   | $243.99 | Authorized dealer            |
```

### 8. Price Tracking Across Queries

Track price movement by saving snapshots over time.

**Strategy:**
1. Run the same query (or detail lookup) on a schedule
2. Store `extracted_price` and `extracted_old_price` per seller with a timestamp
3. Compare across runs to detect drops, restocks, sale starts

**Tip:** Use `no_cache=true` for guaranteed fresh prices when tracking. Skip cache only when freshness matters — caching saves credits during exploration.

### 9. Multi-Market Price Comparison

Compare a product's price across countries.

**Strategy:**
1. Run the same `q` with different `gl` / `hl` / `google_domain` combinations (e.g., `gl=us`, `gl=uk`, `gl=de`)
2. Convert prices to a common currency for comparison
3. Note that product availability and exact SKUs may differ by market

**Use when:** User is researching gray-market imports, traveling shoppers, or competitive pricing analysis.

### 10. Category Browsing

Use `categorized_shopping_results[]` from a broad query to discover product categories Google groups under the search.

**Strategy:**
1. Search broadly (e.g., `q=office furniture`)
2. Read `categorized_shopping_results[]` to see Google's category groupings ("Ergonomic chairs", "Standing desks", "Filing cabinets")
3. Drill into a category by re-querying with the category name as `q`

## Filter Quick Reference

| Goal | Parameter | Value |
|------|-----------|-------|
| Cheapest first | `sort_by` | `1` |
| Most expensive first | `sort_by` | `2` |
| Under $X | `max_price` | `<number>` |
| Over $X | `min_price` | `<number>` |
| Price range | `min_price` + `max_price` | `<low>` + `<high>` |
| On-sale items only | `on_sale` | `true` |
| Free shipping only | `free_shipping` | `true` |
| Small business only | `small_business` | `true` |
| Next page (60+) | `start` | `60` |
| Localized to UK | `gl` + `hl` | `uk` + `en` |
| Mobile view | `device` | `mobile` |
| Fresh (no cache) | `no_cache` | `true` |
| Brand / condition / rating | `shoprs` | `<token from filters[]>` |
| Combine `shoprs` tokens | `shoprs` | `<tok1>\|\|<tok2>` |

## Presenting Results

### Product Search Summary Format

For each product, present:

```
🛒 [Title] — $[Price] [⚠️ was $X, N% off]
   Seller: [Source] | ⭐ [Rating] ([Reviews] reviews)
   Shipping: [Delivery info]
   [Badges from extensions: SALE / FREE SHIPPING / TOP RATED]
   Link: [product_link]
```

### Product Detail Summary Format

```
🛒 [Title] — by [Brand]
   ⭐ [Rating] ([Reviews] reviews) | Price range: [price_range]

   📊 Top Insights:
   - Picture Quality: [insight]
   - Battery: [insight]
   - Build: [insight]

   🏬 Sellers (sorted by total):
   1. [Store] — $[Total] ([Price] + $[Shipping])
   2. [Store] — $[Total]
   ...

   ⭐ Rating Distribution:
   ★★★★★ [N] | ★★★★☆ [N] | ★★★☆☆ [N] | ★★☆☆☆ [N] | ★☆☆☆☆ [N]

   💬 Notable Reviews:
   - "[Excerpt]" — [Reviewer], [Rating]/5

   🎨 Variants: [list color/size/storage options]
```

### Deal Hunting Summary Format

```
🔥 Top Deals — "[query]"

1. [Title] — $[Price] (was $[Old Price], -[N]%)
   [Source] | ⭐ [Rating] | Free shipping
2. ...
```

## Common Patterns

### "Find me a [product] under $X"
1. `google_shopping` with `q=<product>` and `max_price=<X>`
2. Optionally add `sort_by=1` to surface cheapest first
3. Present top 5-10 with price, seller, rating, delivery

### "Where can I buy [specific product] cheapest?"
1. `google_shopping` search to find the canonical listing
2. Pick the matching result and grab its `immersive_product_page_token`
3. `google_immersive_product` with `more_stores=true`
4. Sort `stores[]` by `total`, present comparison table

### "What's on sale for [category]?"
1. `google_shopping` with `q=<category>` and `on_sale=true`
2. Sort presented results by discount percentage (compute from `extracted_old_price` and `extracted_price`)
3. Highlight largest discounts first

### "Compare [Product A] vs [Product B]"
1. Run `google_shopping` for each
2. Pull `immersive_product_page_token` for both
3. `google_immersive_product` for each
4. Side-by-side: price, rating, reviews count, top insights, variants
5. Recommend based on user's stated priorities

### "Is [product] worth buying?"
1. `google_immersive_product` lookup
2. Present rating + review count + rating distribution
3. Surface `top_insights` and 2-3 representative `user_reviews`
4. Include `critic_ratings` if present
5. Note price vs typical range from `price_range`

### "Find [product] available in [country]"
1. `google_shopping` with appropriate `gl` and `hl`
2. Optionally set matching `google_domain` (e.g., `google.de`)
3. Note availability differences vs US results

## Tips

- **Always prefer `google_immersive_product` over `google_product`** — Google shut down the older Product service. Use the `immersive_product_page_token` from shopping results.
- **`more_stores=true` is cheap insurance** for seller comparisons. Default returns 3-5 stores; with `more_stores` you get up to 13.
- **`extracted_price` vs `price`** — Always use `extracted_price` (numeric) for sorting, math, and budget filters. The `price` string includes currency symbols and may have formatting quirks.
- **`old_price` signals a deal.** Compute `(extracted_old_price - extracted_price) / extracted_old_price` for percent off. Sort by this to rank deals.
- **Sponsored vs organic** — Ad placements may appear at the top of results. Check `tag` / `extensions` for ad indicators if relevance matters.
- **Pagination cost** — Each page (60 results) costs one SerpApi credit. For broad surveys, the first page is usually plenty.
- **`shoprs` tokens are opaque** — Don't try to construct them manually. Always extract them from a prior response's `filters[]` array.
- **Use `||` to combine `shoprs` filters** — e.g., `shoprs=<brand_token>||<condition_token>` applies both.
- **Sellers change daily.** A product available at 8 sellers today may show 4 tomorrow. Treat `stores[]` snapshots as point-in-time.
- **Localization affects pricing currency.** `gl=uk` returns prices in GBP, `gl=de` in EUR, etc. Note the currency before comparing.
- **Cache awareness** — Results are cached for one hour by default. Use `no_cache=true` for price tracking, leave default for general exploration.
- **`location` ≠ `gl`** — `gl` sets the country market; `location` sets a city/region origin for the searcher (affecting local availability, taxes, delivery estimates). Combine both when relevance demands it.
- **`uule` is mutually exclusive with `location`** — Use one or the other.
- **Watch for variants.** A `google_immersive_product` response often lists color/size/storage variants. Each variant has its own page token for drill-down.
