---
name: serp-ads
description: >
  Foundational skill for SerpApi ad-related APIs — Google Search paid ads, shopping results,
  local service ads, and the Google Ads Transparency Center. Use when: (1) extracting paid
  search ads (text ads, sitelinks, extensions) from Google Search results, (2) scraping
  shopping/product listing ads from Google Search, (3) extracting local service ads from
  Google Search results, (4) researching an advertiser's ad creatives via the Google Ads
  Transparency Center, (5) getting detailed ad information (text, image, video creatives)
  from the Transparency Center, (6) analyzing competitor ad strategies or ad copy,
  (7) monitoring paid search placements for specific keywords, (8) filtering ads by platform,
  region, date range, or creative format. This is the base SerpApi ads skill — specialized
  skills may reference it for ad intelligence, competitor analysis, or PPC monitoring workflows.
metadata: {"openclaw": {"emoji": "📢", "requires": {"env": ["SERPAPI_KEY"]}, "primaryEnv": "SERPAPI_KEY"}}
---

# SerpApi Ads

Extract paid advertising data from Google Search results and research advertiser creatives via the Ads Transparency Center, all through SerpApi's structured JSON API.

## Setup

Requires `SERPAPI_KEY` environment variable. All requests go to `https://serpapi.com/search` as GET requests with `api_key` parameter.

## Two API Surfaces

| Surface | Engine | Purpose |
|---------|--------|---------|
| **Google Search Ads** | `google` | Extract `ads`, `shopping_results`, `local_ads` from search results |
| **Ads Transparency Center** | `google_ads_transparency_center` | Research all ad creatives by advertiser |
| **Ads Transparency Details** | `google_ads_transparency_center_ad_details` | Get detailed info on a specific ad creative |

---

## 1. Google Search Ads

Paid ads appear in standard Google Search results (`engine=google`). They are returned in three separate arrays alongside organic results.

### Extract Text Ads

```bash
curl -s "https://serpapi.com/search?engine=google&q=QUERY&api_key=$SERPAPI_KEY"
```

Text ads appear in the `ads` array. Each ad includes:

| Field | Description |
|-------|-------------|
| `position` | Position within the ad block |
| `block_position` | Where on page: `top`, `bottom`, `right` |
| `title` | Ad headline |
| `link` | Destination URL |
| `displayed_link` | Visible URL shown to users |
| `tracking_link` | Google click-tracking URL |
| `description` | Ad copy text |
| `source` | Advertiser name |
| `sitelinks[]` | Extended links with `title`, `link`, `snippets[]` |
| `extensions[]` | Ad extensions (callouts, ratings, etc.) |
| `thumbnail` | Image thumbnail URL (when present) |

**Hotel/travel ads** additionally include: `price`, `extracted_price`, `rating`, `reviews`.

**Vehicle ads** include a `vehicles_for_sale[]` array with: `title`, `thumbnail`, `price`, `extracted_price`, `condition`, `mileage`, `extracted_mileage`, `dealership`, `location`, `link`.

**Bottom/mobile ads** may include `links[]` with location info (address, hours, map image).

### Extract Shopping Results

Shopping/product listing ads appear in the `shopping_results` array:

```bash
curl -s "https://serpapi.com/search?engine=google&q=gaming+mouse&api_key=$SERPAPI_KEY"
```

Each shopping result includes:

| Field | Description |
|-------|-------------|
| `position` | Position in the carousel |
| `block_position` | Usually `top` |
| `title` | Product name |
| `price` / `extracted_price` | Display price and numeric value |
| `link` | Product page URL |
| `source` | Retailer name |
| `rating` / `reviews` | Star rating and review count |
| `thumbnail` | Product image URL |
| `shipping` | Shipping info (e.g., "Free shipping") |
| `extensions[]` | Product attributes (color, material, etc.) |

### Extract Immersive Products

For many product queries, Google returns `immersive_products` instead of (or alongside) classic `shopping_results`. This is a richer product carousel with additional fields.

```bash
curl -s "https://serpapi.com/search?engine=google&q=laptops&api_key=$SERPAPI_KEY"
```

> **Important:** Check for both `shopping_results` and `immersive_products` in the response — Google decides which format to serve based on the query.

Each immersive product includes:

| Field | Description |
|-------|-------------|
| `title` | Product name |
| `source` | Retailer name |
| `source_logo` | Retailer logo URL (optional) |
| `price` / `extracted_price` | Display price and numeric value |
| `original_price` / `extracted_original_price` | Pre-sale price (optional) |
| `rating` / `reviews` | Star rating and review count |
| `thumbnail` | Product image URL |
| `category` | Product category (optional, e.g., "Grills") |
| `delivery` | Delivery info (e.g., "Free by 6/10") |
| `returns` | Return policy (e.g., "30-day returns") |
| `location` | Availability note (e.g., "Also nearby") |
| `extensions[]` | Badges/labels (e.g., "SALE", "LOW PRICE", "14% OFF") |
| `snippets[]` | Review snippets with `text`, `link`, `source` |
| `immersive_product_page_token` | Token for the `google_immersive_product` engine (full product details) |
| `serpapi_link` | SerpApi link to drill into full product details |

### Extract Local Ads

Local service ads appear in the `local_ads` object for location-based queries:

```bash
curl -s "https://serpapi.com/search?engine=google&q=plumbing&device=mobile&api_key=$SERPAPI_KEY"
```

> **Note:** Local ads are more reliably returned with `device=mobile`. Desktop results may not include them for the same query.

The `local_ads` object contains:
- `title` — summary heading (e.g., "40+ plumbers nearby")
- `see_more_text` — link text for expanded results
- `serpapi_link` — direct link to the full Google Local Services results
- `ads[]` — array of individual service provider ads

Each local ad includes:

| Field | Description |
|-------|-------------|
| `title` | Business name |
| `link` | Business profile URL |
| `rating` | Star rating |
| `rating_count` | Number of ratings (integer) |
| `badge` | Trust badge (e.g., "GOOGLE GUARANTEED", "GOOGLE SCREENED") |
| `type` | Type of service advertised |
| `service_area` | Service area (e.g., "Serves Dracut") |
| `hours` | Operating hours (e.g., "Open 24/7", "Open now") |
| `years_in_business` | Tenure (e.g., "22 years in business") |
| `phone` | Phone number |
| `thumbnail` | Business thumbnail URL |
| `highlighted_details[]` | Key details highlighted on the ad (e.g., "Family owned", "Flat $89/hour", "Licensed & insured") |

> **Tip:** For the full local services listing, follow `local_ads.serpapi_link` which points to `engine=google_local_services`.

### Key Parameters for Search Ads

All standard `engine=google` parameters work. Most relevant for ads:

| Parameter | Description |
|-----------|-------------|
| `q` | Search query (required) |
| `location` | Geographic location for localized ads |
| `gl` | Country code (e.g., `us`, `uk`, `de`) |
| `hl` | Language code |
| `device` | `desktop` (default), `mobile`, `tablet` — mobile shows different ad layouts |
| `num` | Number of results per page |
| `no_cache` | `true` to force fresh results |

---

## 2. Google Ads Transparency Center

A separate engine for researching what ads an advertiser is running across Google's platforms.

### Search by Advertiser

```bash
curl -s "https://serpapi.com/search?engine=google_ads_transparency_center&advertiser_id=AR17828074650563772417&api_key=$SERPAPI_KEY"
```

### Search by Domain/Text

```bash
curl -s "https://serpapi.com/search?engine=google_ads_transparency_center&text=apple.com&api_key=$SERPAPI_KEY"
```

Either `advertiser_id` or `text` is required. Multiple advertiser IDs can be comma-separated.

### Parameters

| Parameter | Description |
|-----------|-------------|
| `advertiser_id` | Google Advertiser ID (e.g., `AR17828074650563772417` for Tesla). Found in Transparency Center URLs |
| `text` | Free-text/domain search. Alternative to `advertiser_id` |
| `platform` | Filter by platform: `SEARCH`, `YOUTUBE`, `SHOPPING`, `MAPS`, `PLAY` |
| `political_ads` | `true` to show only political ads. Requires `region` |
| `region` | Region code (see SerpApi docs for full list) |
| `start_date` | Start date `YYYYMMDD`. For "today", set `end_date` = start + 1 day |
| `end_date` | End date `YYYYMMDD` |
| `creative_format` | Filter by format: `text`, `image`, `video` |
| `num` | Results per page (default 40, max 100) |
| `next_page_token` | Pagination token from `serpapi_pagination.next_page_token` |

### Response: `ad_creatives[]`

Each creative includes:

| Field | Description |
|-------|-------------|
| `advertiser_id` | Advertiser's Google ID |
| `advertiser` | Advertiser name |
| `ad_creative_id` | Creative ID (for drilling into details) |
| `format` | `text`, `image`, or `video` |
| `target_domain` | Target website (when searched by text/domain) |
| `image` | Preview image URL |
| `width` / `height` | Image dimensions |
| `first_shown` / `last_shown` | Unix timestamps |
| `details_link` | Direct link to Google Transparency Center page |
| `serpapi_details_link` | SerpApi link for Ad Details API |

Pagination via `serpapi_pagination.next_page_token`.

---

## 3. Ad Details (Transparency Center)

Drill into a specific ad creative for full details.

```bash
curl -s "https://serpapi.com/search?engine=google_ads_transparency_center_ad_details&advertiser_id=ADVERTISER_ID&creative_id=CREATIVE_ID&api_key=$SERPAPI_KEY"
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `advertiser_id` | Yes | Google Advertiser ID |
| `creative_id` | Yes | Google Creative ID |
| `region` | No | Region filter |

### Response

`search_information` includes:
- `format` — `text`, `image`, or `video`
- `last_shown` — Unix timestamp
- `regions[]` — list of regions where the ad ran, each with `region`, `region_name`, `first_shown`, `last_shown`

`ad_creatives[]` contains the full creative details, which vary by format:

**Text ads:** `title`, `headline`, `snippet`, `visible_link`, `advertiser_logo`, `sitelink_texts[]`

**Image ads:** `call_to_action`, `headline`, `snippet`, `link`, `image`, `advertiser_logo`

**Video ads:** `call_to_action`, `headline`, `snippet`, `link`, `video`, `advertiser_logo`

---

## Common Patterns

### Monitor Competitor Ad Placements

1. Search with competitor's target keywords using `engine=google`
2. Extract `ads` array — filter by competitor's domain in `link` or `displayed_link`
3. Track `block_position`, `position`, `description`, `sitelinks` over time

### Research Competitor's Full Ad Library

1. Search Transparency Center with `text=competitor.com`
2. Browse `ad_creatives[]` to see all active creatives
3. Filter by `creative_format` or `platform` to focus on specific ad types
4. Drill into interesting creatives with the Ad Details API

### Compare Shopping Prices Across Retailers

1. Search `engine=google&q=PRODUCT_NAME`
2. Extract `shopping_results[]`
3. Compare `extracted_price`, `source`, `rating`, `shipping` across retailers

### Track Ad Copy Variations

1. Run the same query repeatedly (use `no_cache=true`)
2. Collect `ads[].description`, `ads[].title`, `ads[].sitelinks`
3. Diff changes to detect A/B testing or seasonal copy adjustments

## Error Handling

- Check `search_metadata.status` — should be `"Success"`
- On error, `error` field contains the message
- Cache expires after 1h; use `no_cache=true` for fresh results (costs a search credit)
- Don't combine `no_cache` and `async`
- Transparency Center: if `advertiser_id` is invalid, API returns an error. Find valid IDs from the Transparency Center URL pattern: `adstransparency.google.com/advertiser/ADVERTISER_ID`

## Detailed Reference

For complete parameter tables, all response field schemas, and extended JSON examples: read [references/api-reference.md](references/api-reference.md).
