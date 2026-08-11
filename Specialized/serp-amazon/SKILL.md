---
name: serp-amazon
display_name: Amazon
description: >
  Specialized skill for Amazon workflows via SerpApi — product search, product detail lookup,
  price comparison, marketplace differences, filtering, reviews, and best-sellers. Use when:
  (1) searching Amazon for products by keyword, (2) looking up a specific product by ASIN
  for price, availability, and variations, (3) comparing prices across Amazon marketplaces
  (amazon.com vs amazon.co.uk vs amazon.de etc.), (4) filtering search results by brand,
  category, rating, or price range, (5) analyzing customer reviews and AI review insights
  for a product, (6) finding best-sellers or new releases in a category, (7) distinguishing
  sponsored ads from organic results, (8) checking Prime eligibility and delivery options,
  (9) extracting product variants (size, color, flavor) and their ASINs, (10) building
  product comparison reports, (11) any task involving Amazon product data. This skill builds
  on the foundational serpapi skill for all API details.
dependencies:
  - serpapi
metadata: {"openclaw": {"emoji": "📦"}}
---

# Amazon Workflows

Product search, detail lookup, price comparison, and review analysis via SerpApi's Amazon Search and Amazon Product engines. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engines: `amazon`, `amazon_product`)

## Core Concepts

### Two Engines, Two Purposes

| Engine | Use For | Required Param |
|--------|---------|----------------|
| `amazon` | Search results, browsing a category, filtering | `k` (query) or `node` (category) |
| `amazon_product` | Full details for one product (price, variants, reviews) | `asin` |

The typical pattern is: **search with `amazon` → pick an ASIN → fetch full details with `amazon_product`**.

### ASIN

The Amazon Standard Identification Number is the universal product ID. Every Amazon product has one (10 characters, e.g., `B08N5WRWNW`). ASINs may differ across marketplaces for the same product — a US ASIN may not exist on amazon.de.

### Marketplace Domains

The `amazon_domain` parameter targets a specific marketplace. Default is `amazon.com`.

| Domain | Market |
|--------|--------|
| `amazon.com` | United States |
| `amazon.co.uk` | United Kingdom |
| `amazon.ca` | Canada |
| `amazon.de` | Germany |
| `amazon.fr` | France |
| `amazon.es` | Spain |
| `amazon.it` | Italy |
| `amazon.co.jp` | Japan |
| `amazon.in` | India |
| `amazon.com.mx` | Mexico |
| `amazon.com.br` | Brazil |
| `amazon.com.au` | Australia |
| `amazon.nl` | Netherlands |
| `amazon.se` | Sweden |
| `amazon.ae` | UAE |
| `amazon.sg` | Singapore |

Pair with `language` (e.g., `en_GB`, `de_DE`, `ja_JP`) for localized text.

### Search vs Browse

- **Search:** Pass `k` with a keyword. Returns matching products. Cannot combine with `node`.
- **Browse:** Pass `node` with a category ID (e.g., `6563140011` for Smart Home). Cannot combine with `k`.

### Result Types in Search

A single `amazon` search response can include:
- `organic_results[]` — Standard product listings
- `product_ads[]` — Sponsored product carousel ads
- `sponsored_brands[]` — Brand showcase ads
- `featured_products[]` — Curated sections (e.g., "Recently rated")
- `video_results[]` — Video content with linked products
- `related_searches[]` — Suggested follow-up queries
- `filters[]` — Available refinements with `rh` hashes you can use to narrow further

**Always distinguish sponsored from organic** when presenting to the user — every result has a `sponsored: true/false` flag.

### Pricing Fields

Prices appear as both strings (with currency symbol) and numeric extractions:
- `price` (e.g., `"$29.99"`) + `extracted_price` (e.g., `29.99`)
- `old_price` + `extracted_old_price` — Pre-discount original price
- `price_unit` (e.g., `"$1.13/Ounce"`) + `extracted_price_unit`
- `discount` — Percentage string (e.g., `"-10%"`)

Use the `extracted_*` fields for any math, sorting, or comparison.

## Workflows

### 1. Product Search by Keyword

Use the **serpapi** skill's wrapper script with the `amazon` engine.

**Required:**
- `k` — Search query (e.g., `"wireless earbuds"`)

**Common options:**
- `amazon_domain` — Marketplace (default `amazon.com`)
- `page` — Page number, 1-based
- `s` — Sort order (see table below)
- `delivery_zip` — ZIP for accurate shipping filters

**Sort options (`s` parameter):**

| Value | Meaning |
|-------|---------|
| `relevanceblender` | Featured (default) |
| `price-asc-rank` | Price: Low to High |
| `price-desc-rank` | Price: High to Low |
| `review-rank` | Avg Customer Review |
| `date-desc-rank` | Newest Arrivals |
| `exact-aware-popularity-rank` | Best Sellers |

**What to present:** Top 5-10 organic results with title, price, rating, review count, Prime eligibility, badges. Flag sponsored separately. Show related searches if user might want to refine.

### 2. Filtering with `rh`

The `rh` parameter is Amazon's structured filter syntax. Values come from the `filters[]` block in a prior search response — never invent them.

**Format:** `key:value_id` pairs separated by commas. Example: `n:283155,p_72:1248897011` (Books category with 4+ star rating).

**Common filter prefixes seen in responses:**
- `n:<id>` — Category node
- `p_72:<id>` — Customer review rating tier
- `p_36:<min>-<max>` — Price range (in cents)
- `p_89:<brand_id>` — Brand
- `p_n_feature_browse-bin:<id>` — Feature attributes (Prime, free shipping, etc.)

**Workflow:**
1. Run an initial `amazon` search with `k`
2. Inspect the `filters[]` block in the response — each filter option has a hash value
3. Re-run the search with `rh` set to the chosen filter(s) to refine

Never guess `rh` values. They are marketplace-specific and change.

### 3. Product Detail Lookup by ASIN

Use the `amazon_product` engine.

**Required:**
- `asin` — Product identifier
- `amazon_domain` — Must match where the ASIN exists

**Useful options:**
- `other_sellers` — Set `true` to include third-party seller offers
- `delivery_zip` — ZIP for accurate delivery dates

**Key response sections:**
- Core product: `title`, `description`, `brand`, `price`, `old_price`, `discount`, `rating`, `reviews`, `bought_last_month`, `stock`, `badges`, `thumbnails`
- `variants[]` — Each variant group (e.g., "Size", "Color") with sub-items including their own ASINs and `serpapi_link` for follow-up queries
- `purchase_options` — Different buying methods (`buy_new`, `subscribe_and_save`, `buy_used`)
- `item_specifications` — Key-value spec table
- `about_item` — Bullet-point features
- `product_details` — Dimensions, weight, UPC, bestseller rank
- `bought_together`, `related_products`, `compare_with_similar` — Cross-sell and comparison
- `reviews_information` — AI summary, sentiment insights, individual reviews
- `other_sellers` — Third-party offers (when `other_sellers=true`)

**Presentation pattern:** Lead with title, price (with discount if any), rating, stock. Then variants, key specs, top 3 review insights, and a CTA-style summary of value.

### 4. Price Comparison Across Marketplaces

Compare the same product across different Amazon domains.

**Strategy:**
1. Start with the source marketplace (e.g., `amazon.com`) — get the ASIN
2. For each target marketplace, attempt a product lookup with the same ASIN
3. If the ASIN doesn't exist there, fall back to a keyword search (`k` = product title or model number) on that marketplace to find the local ASIN
4. Compare `extracted_price` across markets — normalize to one currency if needed

**Watch out for:**
- ASINs differ between marketplaces for many products
- Prices are in the marketplace's local currency
- Availability and Prime eligibility vary by region

**Presentation pattern:**

```
📦 [Product Name] — Marketplace Price Comparison

| Marketplace | Price       | Prime | In Stock |
|-------------|-------------|-------|----------|
| amazon.com  | $29.99 USD  | ✅    | ✅       |
| amazon.co.uk| £24.99 GBP  | ✅    | ✅       |
| amazon.de   | €27.50 EUR  | ✅    | ⚠️ Low   |
| amazon.co.jp| ¥3,800 JPY  | ❌    | ✅       |
```

### 5. Category Browse / Best Sellers / New Releases

Browse a category without a keyword by passing `node`.

**Strategy:**
- For best-sellers: `node` = category ID, `s=exact-aware-popularity-rank`
- For new releases: `node` = category ID, `s=date-desc-rank`
- For top-rated: `node` = category ID, `s=review-rank`

To find category IDs, run an initial `k` search and pull `n:` values from the `filters[]` block, or inspect category links in any search result.

### 6. Brand Filtering

To narrow to a specific brand:

**Option A — Filter via `rh`:** Run a baseline search, find the brand's `rh` hash in `filters[]`, then re-run with that `rh`.

**Option B — Query string:** Include the brand name in `k` (e.g., `"sony wireless earbuds"`). Faster but less precise — Sony-adjacent results may sneak in.

Prefer Option A when comparing multiple brands head-to-head or building a clean brand catalog.

### 7. Rating & Price Filtering

**Rating filter:** Use the `p_72:` value from `filters[]` — Amazon offers tiers like "4 Stars & Up", "3 Stars & Up", etc. Each has a different hash.

**Price filter:** Use `p_36:<min>-<max>` where values are in **cents** (or the marketplace's smallest currency unit). For amazon.com: `p_36:2000-5000` = $20 to $50.

**Tip:** Sorting by `price-asc-rank` with a `max_price`-style `rh` filter is more reliable than relying on sort alone, which doesn't cap the upper bound.

### 8. Review Analysis

Fetch full reviews via `amazon_product` — the `reviews_information` section is the gold mine.

**Key fields:**
- `summary.text` — Aggregated sentiment narrative
- `summary.insights[]` — AI-clustered topics with sentiment (e.g., "Battery life: positive, 412 mentions"). Each has `title`, `sentiment`, `mentions`, `summary`, `examples[]`
- `summary.customer_reviews` — Star distribution percentages
- `authors_reviews[]` — Individual reviews with `title`, `text`, `rating`, `date`, `author`, `verified_purchase`, `helpful_votes`, plus optional `images[]` and `video`

**Presentation pattern:**

```
⭐ [Product] — Review Analysis ([N] reviews, [X.X] avg)

📊 Distribution:
   ★★★★★ [%] | ★★★★☆ [%] | ★★★☆☆ [%] | ★★☆☆☆ [%] | ★☆☆☆☆ [%]

💡 What customers say:
   ✅ [Insight title]: [summary] ([positive]/[total] mentions)
   ✅ [Insight title]: [summary]
   ⚠️ [Insight title]: [summary] ([negative]/[total] mentions)

📝 Notable reviews:
   • "[Title]" — ★[rating], verified — [excerpt]
   • "[Title]" — ★[rating] — [excerpt]
```

### 9. Variant Exploration

Many products have variants (size, color, flavor). The `variants[]` array groups them — each group has a category title and an `items[]` list of ASINs.

**To get pricing for each variant:**
1. Fetch the main product with `amazon_product`
2. For each variant in `variants[].items[]`, follow the `serpapi_link` or run a new `amazon_product` query with that variant's ASIN
3. Compare prices, availability, and ratings across variants

**Tip:** The `selected: true` flag marks which variant the current ASIN refers to.

### 10. Comparing Similar Products

Two approaches:

**Approach A — Built-in comparison:** The `amazon_product` response includes `compare_with_similar` when Amazon offers it. This is curated by Amazon and includes specs side-by-side.

**Approach B — Manual comparison:** Fetch each product separately and build your own table from `item_specifications`, `price`, `rating`, `bought_last_month`, and key `about_item` bullets.

**Presentation pattern:**

```
📦 Product Comparison

| Feature       | Product A   | Product B   | Product C   |
|---------------|-------------|-------------|-------------|
| Price         | $29.99      | $34.99      | $24.99      |
| Rating        | ⭐ 4.6       | ⭐ 4.4       | ⭐ 4.2       |
| Reviews       | 12,403      | 8,201       | 24,150      |
| Prime         | ✅          | ✅          | ❌          |
| [Key spec]    | [value]     | [value]     | [value]     |
| Bought/month  | 30K+        | 10K+        | 50K+        |

🏆 Best Value: Product C ($24.99, 50K+ monthly buyers)
🏆 Best Rated: Product A (⭐ 4.6)
```

### 11. Third-Party Seller Offers

For one ASIN, see all sellers (not just Amazon's primary offer).

**Strategy:** Run `amazon_product` with `other_sellers=true`. The `other_sellers[]` array contains each offer with `price`, `delivery`, `rating`, `reviews`, and any `notes` (e.g., "Used - Like New").

Useful for: finding the lowest total cost, checking for used/refurbished options, identifying when third-party sellers undercut Amazon, evaluating seller reputation.

## Filter Quick Reference

| Goal | Parameter | Value |
|------|-----------|-------|
| Search by keyword | `k` | `"product name"` |
| Browse category | `node` | Category ID |
| Specific marketplace | `amazon_domain` | `amazon.co.uk` |
| Sort cheapest first | `s` | `price-asc-rank` |
| Sort by rating | `s` | `review-rank` |
| Best sellers | `s` | `exact-aware-popularity-rank` |
| Newest arrivals | `s` | `date-desc-rank` |
| Refine with filters | `rh` | From `filters[]` in prior response |
| Next page | `page` | `2`, `3`, ... |
| Local delivery | `delivery_zip` | ZIP code |
| Skip autocorrect | `dc` | `true` |
| Product detail | engine | `amazon_product` + `asin` |
| Include 3rd-party | `other_sellers` | `true` |

## Common Patterns

### "Find me the best [product] under $X"
1. `amazon` search with `k="[product]"`, `s=review-rank`
2. From `filters[]`, find the price filter hash for the target range
3. Re-run with `rh` set to the price filter
4. Present top 5 by rating, noting price, reviews, Prime status

### "What does [specific product] cost?"
1. If user gives ASIN, go straight to `amazon_product`
2. If user gives a product name, run `amazon` search first, pick the top organic match, then `amazon_product` on its ASIN
3. Present price, discount %, Prime, stock, and a quick value verdict

### "Is [product] worth buying?"
1. `amazon_product` lookup for the ASIN
2. Present rating, review count, `bought_last_month`
3. Surface the top positive and negative insights from `reviews_information.summary.insights`
4. Cite 2-3 representative verified reviews
5. Recommend based on sentiment balance

### "Compare [Product A] vs [Product B]"
1. Resolve each to an ASIN via `amazon` search if needed
2. `amazon_product` for each
3. Build a comparison table from price, rating, reviews, key specs
4. Pull top insight from each product's reviews
5. Recommend based on the user's stated priorities

### "Cheapest [product] across Amazon marketplaces"
1. `amazon` search on the user's home domain, get the top ASIN
2. Loop through target marketplaces — try `amazon_product` with the same ASIN; fall back to a fresh search if the ASIN doesn't exist
3. Normalize prices to one currency for fair comparison
4. Note shipping restrictions — many marketplaces don't ship internationally

### "Top-rated [category] on Amazon UK"
1. `amazon` engine, `amazon_domain=amazon.co.uk`, `k="[category]"`, `s=review-rank`
2. Optionally narrow with a 4+ star rating `rh` filter
3. Present top 5-10 with rating, reviews, price in GBP

### "Show me sponsored vs organic for [keyword]"
1. `amazon` search with `k`
2. Split results by the `sponsored` flag
3. Present `product_ads` and `sponsored_brands` separately from `organic_results`
4. Note which brands are paying for visibility vs ranking organically

## Tips

- **Use extracted fields for math.** `extracted_price` is a float; `price` is a string with currency symbol. Never parse `price` yourself.
- **Sponsored ≠ organic.** Always check the `sponsored` flag and clearly label paid results when presenting to the user.
- **ASINs are marketplace-specific.** A US ASIN may not work on amazon.de. When in doubt, search by product name on the target marketplace.
- **`rh` values are dynamic.** Never invent filter hashes. Always derive them from the `filters[]` block of a prior search response in the same marketplace.
- **`k` and `node` are mutually exclusive.** Use one or the other, not both.
- **Set `delivery_zip` for accuracy.** Prices, Prime eligibility, and delivery dates vary by location. A ZIP makes results match what the user actually sees.
- **`bought_last_month` is a velocity signal.** "30K+ bought" is a strong demand indicator that complements raw review count.
- **Variants share a product page.** When `amazon_product` returns a `variants[]` block, each item has its own ASIN — drill in for variant-specific pricing.
- **AI review insights are the highlight.** `reviews_information.summary.insights` gives you sentiment-tagged topic clusters — far more useful than reading reviews one by one.
- **Watch the `stock` field.** Values like "Only 3 left in stock" or "Currently unavailable" matter for the user's decision and shouldn't be omitted.
- **`other_sellers=true` costs a bigger response.** Only request it when comparing third-party offers — for a plain detail lookup, leave it off.
- **Language pairing.** Pair `amazon_domain` with a matching `language` (e.g., `amazon.de` with `de_DE`) for native-language titles and descriptions.
- **Pagination caps out.** Amazon typically shows ~20 pages of results. For deep catalog work, refine with `rh` or `node` rather than paging endlessly.
- **`dc=true`** skips autocorrected results — useful when searching for a specific model number or unusual term that Amazon keeps "fixing".
