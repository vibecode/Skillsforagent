---
name: serp-walmart
display_name: Walmart
description: >
  Specialized skill for Walmart workflows via SerpApi — product search, category browsing,
  filtering, product detail lookups, variants and sellers, customer reviews collection,
  store-specific pricing, and competitor comparison. Use when: (1) searching Walmart for
  products by keyword, (2) browsing or filtering a Walmart category, (3) filtering by brand,
  price range, rating, or shipping options, (4) finding products at a specific Walmart store
  via store_id, (5) fetching detailed product info (specs, variants, sellers, in-stock status),
  (6) collecting customer reviews and rating histograms for a Walmart product, (7) comparing
  Walmart prices vs other retailers (e.g., Amazon), (8) tracking prices for deal detection,
  (9) finding NextDay or two-day shipping eligible items, (10) any task involving Walmart
  product data, pricing, variants, or reviews. This skill builds on the foundational serpapi
  skill for all API details.
dependencies:
  - serpapi
metadata: {"openclaw": {"emoji": "🛍️"}}
---

# Walmart Workflows

Product search, detail lookup, and review collection via SerpApi's Walmart engines. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engines: `walmart`, `walmart_product`, `walmart_product_reviews`)

## Core Concepts

### Three Engines

| Engine | Purpose | Key Input |
|--------|---------|-----------|
| `walmart` | Product search and category browsing | `query` or `cat_id` |
| `walmart_product` | Single product detail page | `product_id` (preferred) or `us_item_id` |
| `walmart_product_reviews` | Customer reviews for a product | `product_id` |

### Product Identifiers

Walmart uses two ID systems — know which to use where:

| ID | Format | Where it comes from | Used in |
|----|--------|---------------------|---------|
| `product_id` | Numeric, from URL `walmart.com/ip/{product_id}` | Product page URL | **Preferred** for `walmart_product` and `walmart_product_reviews` (faster) |
| `us_item_id` | Numeric, internal Walmart item ID | Search `organic_results[].us_item_id` | Fallback when `product_id` unavailable |

**Default to `product_id`** when fetching product detail or reviews — SerpApi notes it's faster than `us_item_id`.

### Localization

| Domain | Market | Notes |
|--------|--------|-------|
| `walmart.com` | United States (default) | Full feature set |
| `walmart.com.mx` | Mexico | Some `sort` options unavailable |

### Response Structure — Search

A `walmart` search returns:

- **`organic_results[]`** — Product listings:
  - `us_item_id`, `product_id`, `title`, `description`
  - `rating` (float, 1-5), `reviews` (count), `thumbnail`
  - `seller_id`, `seller_name`
  - `primary_offer.offer_price`, `primary_offer.min_price`, `primary_offer.max_price`, `currency`
  - `sponsored` (boolean), `two_day_shipping` (boolean)
  - `product_page_url`
- **`filters[]`** — Available facets (departments, brand, price, rating, fulfillment)
- **`pagination`** — `current_page`, `next_page` link
- **`related_queries[]`** — Suggested searches with relevance scores
- **`search_metadata`** — Request ID, timing, status

### Response Structure — Product Detail

A `walmart_product` response returns:

- **Identifiers** — `us_item_id`, `product_id`, `upc`
- **`price_map`** — `price` (current), `was_price` (original), `currency`
- **Inventory** — `in_stock`, `min_quantity`, `max_quantity`
- **`variant_swatches[]`** — Color/size options, each with its own `product_id` and pricing
- **Content** — `title`, `short_description_html`, `detailed_description_html`, `categories[]`, `specification_highlights[]`, `manufacturer`
- **`images[]`** — Product photo URLs
- **`offers[]`** — Multiple seller offers (`seller_id`, `seller_name`, price)
- **`rating`**, **`reviews`** — Aggregate score and review count
- **`reviews_results`** — Star distribution, top positive, top negative
- **Fulfillment** — `shipping_option`, `pickup_option`, `delivery_option` (each with availability/timing)
- **`badges[]`** — Walmart badges (Best Seller, Rollback, etc.)

### Response Structure — Reviews

A `walmart_product_reviews` response returns:

- **Product info** — Name, URL, categories
- **Aggregate** — `overall_rating`, `total_count`, `ratings[]` (per-star counts 1-5)
- **`reviews[]`** — Individual reviews:
  - `title`, `text`, `rating` (1-5 integer)
  - `positive_feedback`, `negative_feedback` (helpfulness counts)
  - `review_submission_time`, `user_nickname`
  - `customer_type[]` (e.g., `"VerifiedPurchaser"`)
- **Featured** — `top_positive`, `top_negative` reviews
- **Pagination** — Current `page`, `next` link, available pages

## Workflows

### 1. Basic Product Search

Use the **serpapi** skill's wrapper with the `walmart` engine.

**Required:** `query` *or* `cat_id`

**Useful parameters:**
- `page` — Page number (1-100, default 1)
- `sort` — `best_match` (default), `price_low`, `price_high`, `best_seller`, `rating_high`, `new`
- `min_price` / `max_price` — Price range
- `facet` — Attribute filters as `key:value` pairs joined with `||` (e.g., `brand:Samsung||fulfillment_speed_1:Next-Day`)
- `nd_en` — Set `true` for NextDay-eligible items only
- `store_id` — Limit to a specific Walmart store
- `include_filters` — Set `true` to include available facets in response (useful for discovering filter values)

**Presentation pattern:** Show top 5-10 organic results with title, price, rating, shipping, and link. Flag sponsored items.

### 2. Filtering with Facets

The `facet` parameter is the workhorse for narrowing results. Values are joined with `||`:

```
facet=brand:Samsung||price:50-100||rating:4_up
```

To discover available facet keys/values, run a search with `include_filters=true` and inspect the `filters` array — it lists every facet (department, brand, price bucket, rating, fulfillment speed, customer rating, etc.) with usable values.

**Common facet quick reference:**

| Goal | Facet |
|------|-------|
| Specific brand | `brand:Apple` |
| 4+ stars only | `customer_rating:4_up` (verify exact key via `include_filters`) |
| NextDay shipping | `fulfillment_speed_1:Next-Day` or use `nd_en=true` |
| Walmart-fulfilled | Check `seller` or `retailer` facet |
| In a department | `cat_id:976759` (use `cat_id` param directly) |

**Strategy:** First search returns a broad list. If too noisy, run `include_filters=true`, pick the relevant facet keys, then re-search with `facet=...`.

### 3. Category Browsing

To browse a category without a search query, pass `cat_id` instead of `query`. Get a category ID from a Walmart category URL (e.g., `walmart.com/cp/electronics/3944` → `cat_id=3944`).

Combine `cat_id` with `sort=best_seller` to surface a category's top sellers, or `sort=new` for fresh arrivals.

### 4. Store-Specific Search & Pricing

Walmart prices and availability vary by store. Pass `store_id` on `walmart` search or `walmart_product` to get store-specific data.

**Use cases:**
- Local inventory check before recommending a product
- Comparing prices across nearby stores
- Confirming pickup availability

**How to get a store ID:** From a Walmart store URL or the user's preferred store on walmart.com. Without `store_id`, results use Walmart's default fulfillment center for the requesting IP.

### 5. Product Detail Lookup

Use the `walmart_product` engine with `product_id` (preferred) or `us_item_id` from a prior search.

**What to extract:**
- **Pricing** — `price_map.price`, `price_map.was_price` (use both to compute % off)
- **Stock** — `in_stock`, `max_quantity` (low max = limited stock)
- **Variants** — Iterate `variant_swatches[]` for color/size pricing differences. Each variant has its own `product_id`, so fetch separately for full detail.
- **Specs** — `specification_highlights[]` for headline specs; `detailed_description_html` for full description
- **Sellers** — `offers[]` lists all third-party sellers. Compare prices and seller ratings.
- **Fulfillment** — `shipping_option`, `pickup_option`, `delivery_option` — only one is typically the fastest; surface that to the user.

### 6. Variant Comparison

When a product has color/size variants, each variant may have a different price, stock status, and rating.

**Strategy:**
1. Fetch the base product with `walmart_product`
2. Read `variant_swatches[]` — each entry has a `product_id`
3. For each variant of interest, fetch its `walmart_product` separately
4. Present a comparison table (color/size × price × stock × delivery)

**Tip:** Only fetch variants that match user constraints (e.g., specific size) to save credits.

### 7. Customer Reviews Collection

Use `walmart_product_reviews` with `product_id`.

**Useful parameters:**
- `page` — Paginate through reviews
- `rating` — Filter by star rating (`1`–`5`) — useful for pulling only negative or only positive reviews
- `sort` — `relevancy` (default), `helpful`, `submission-desc` (newest), `submission-asc` (oldest), `rating-desc`, `rating-asc`

**Strategy:**
1. Fetch page 1 with default sort → get `overall_rating`, `total_count`, `ratings[]` histogram, `top_positive`, `top_negative`
2. For sentiment deep dives, fetch `sort=submission-desc` for recency or `rating=1` / `rating=2` for complaints
3. Verified-purchaser reviews (`customer_type` includes `"VerifiedPurchaser"`) carry more weight

**Pagination:** Plan based on `total_count`. Sample rather than exhaust for products with thousands of reviews.

### 8. Walmart vs Competitors Comparison

Compare a product across Walmart and another retailer (e.g., Amazon via the `amazon` or `google_shopping` engine).

**Strategy:**
1. Search the product on Walmart → get price, rating, shipping
2. Search the same product on the comparison retailer
3. Build a side-by-side table:

```
| Retailer | Price  | Rating | Reviews | Shipping       |
|----------|--------|--------|---------|----------------|
| Walmart  | $XX.XX | ⭐ 4.5  | 1,240   | Free 2-day     |
| Amazon   | $YY.YY | ⭐ 4.6  | 3,890   | Prime same-day |
```

4. Highlight the better deal accounting for shipping, return policy, and review volume.

### 9. Price & Deal Tracking

To detect deals:
1. Run `walmart` search sorted by `price_low` for the user's query
2. For each result, check `was_price` vs `price` — large gaps indicate Rollback/clearance
3. Look for `badges[]` on the detail page (e.g., "Rollback", "Clearance", "Best Seller")
4. For ongoing tracking, store `product_id` and re-fetch `walmart_product` periodically

### 10. NextDay / Fast Shipping

For "I need it tomorrow" queries:
- Add `nd_en=true` to the search to filter for NextDay-eligible items
- Or use the appropriate `fulfillment_speed_1` facet
- On the product detail, check `shipping_option` and `delivery_option` for guaranteed dates

## Sort Quick Reference

| Goal | `sort` value |
|------|--------------|
| Most relevant | `best_match` (default) |
| Cheapest first | `price_low` |
| Most expensive first | `price_high` |
| Popular | `best_seller` |
| Highest rated | `rating_high` |
| Newest | `new` |

## Reviews Sort Quick Reference

| Goal | `sort` value |
|------|--------------|
| Most helpful | `helpful` |
| Newest reviews | `submission-desc` |
| Oldest reviews | `submission-asc` |
| Highest first | `rating-desc` |
| Lowest first | `rating-asc` |
| Default | `relevancy` |

## Presenting Results

### Search Result Format

For each product in search results:

```
🛍️ [Title]
   $[price] [~~$was_price~~ if applicable]  ⭐ [rating] ([reviews] reviews)
   Seller: [seller_name] | [Two-day | NextDay | Pickup] shipping
   [⚠️ Sponsored] [🔖 Rollback / Best Seller badge]
   Link: [product_page_url]
```

### Product Detail Format

```
🛍️ [Title] by [manufacturer]
   💵 $[price] (was $[was_price], [N]% off)
   📦 [In stock | Out of stock] | Ships [option] | Pickup [option]
   ⭐ [rating] ([reviews] reviews)

   Key specs:
   - [spec 1]
   - [spec 2]

   Variants: [N colors, M sizes]
   Sellers: [N offers, lowest $X via {seller}]
```

### Reviews Summary Format

```
🛍️ [Product] — Reviews

⭐ [overall_rating] / 5  ([total_count] reviews)

Distribution:
  ★★★★★ [count] ████████████
  ★★★★☆ [count] ██████
  ★★★☆☆ [count] ███
  ★★☆☆☆ [count] █
  ★☆☆☆☆ [count] █

👍 Top positive: "[top_positive.title]" — [rating]★
👎 Top negative: "[top_negative.title]" — [rating]★
```

## Common Patterns

### "Find me a [product] on Walmart under $X with good reviews"
1. `walmart` search with `query`, `max_price=X`, `sort=rating_high`
2. Filter results to rating ≥ 4.0 client-side
3. Present top 5 with price, rating, shipping

### "Compare [product] across Walmart sellers"
1. `walmart_product` lookup
2. Iterate `offers[]` — show seller name, price, fulfillment
3. Recommend best value (lowest price + reputable seller + good fulfillment)

### "Is [product] cheaper on Walmart vs Amazon?"
1. Search Walmart → cheapest matching result's price
2. Search Amazon (separate engine) → cheapest matching result
3. Compare unit price, shipping, and rating

### "What do customers say about [product]?"
1. `walmart_product` for overall rating + `reviews_results.top_positive` / `top_negative`
2. `walmart_product_reviews` page 1 with `sort=helpful` for the most useful reviews
3. Optionally `rating=1` and `rating=2` to surface complaints

### "Find NextDay-eligible [product]"
1. `walmart` search with `query`, `nd_en=true`
2. Optionally `sort=best_seller`
3. Confirm on each product detail that `shipping_option` shows NextDay

### "Browse Walmart [category] best sellers"
1. `walmart` search with `cat_id=<category_id>`, `sort=best_seller`
2. No `query` needed
3. Surface top 10 with price and rating

## Tips

- **Prefer `product_id` over `us_item_id`** for detail and review lookups — SerpApi explicitly notes it's faster.
- **Use `include_filters=true`** on a first exploratory search to discover available facet keys before filtering — Walmart's facet keys are not all documented.
- **Facet syntax: `key:value||key:value`** — pipe-pipe separated. Single `|` will not parse.
- **Watch `sponsored: true`** on results — sponsored listings are paid placements, not organic ranking signals.
- **`primary_offer.min_price` vs `offer_price`** — products with variants report a price range; use `min_price` and `max_price` to communicate "starting at $X".
- **`was_price` is the original** — compute discount % as `(was_price - price) / was_price * 100` for headline deal callouts.
- **Variant swatches are pointers, not full data** — each variant's full pricing and stock require a separate `walmart_product` fetch.
- **`store_id` changes prices** — same `product_id` can return different `price_map` values across stores. Be explicit about which store you queried.
- **Verified purchaser weight** — when summarizing reviews, prefer reviews with `customer_type` including `"VerifiedPurchaser"` over anonymous ones.
- **`top_positive` + `top_negative` are free signals** — they're returned in the product detail response, so you often don't need a separate reviews call for a quick sentiment snapshot.
- **Mexico domain caveat** — `walmart.com.mx` doesn't support every `sort` value; fall back to `best_match` if a sort returns no results.
- **Pagination caps at page 100** for search. For exhaustive category scrapes, combine `cat_id` with multiple sorts to broaden coverage.
- **`nd_en=true` is a fast shortcut** for NextDay filtering — simpler than crafting the equivalent facet expression.
- **Currency** — default USD on `walmart.com`, MXN on `walmart.com.mx`. Always read `currency` from `primary_offer` rather than assuming.
