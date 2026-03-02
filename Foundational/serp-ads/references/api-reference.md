# SerpApi Ads — API Reference

Complete parameter and response documentation for all ad-related SerpApi endpoints.

## Table of Contents

1. [Google Search Ads (engine=google)](#google-search-ads)
2. [Shopping Results Schema](#shopping-results-schema)
3. [Local Ads Schema](#local-ads-schema)
4. [Ads Transparency Center (engine=google_ads_transparency_center)](#ads-transparency-center)
5. [Ad Details (engine=google_ads_transparency_center_ad_details)](#ad-details)
6. [Transparency Center Regions](#transparency-center-regions)

---

## Google Search Ads

Ads are returned as part of `engine=google` responses. No special parameters needed — ads appear whenever they exist for the query/location.

### `ads[]` — Full Field Reference

| Field | Type | Description |
|-------|------|-------------|
| `position` | int | Position within the ad block (1-indexed) |
| `block_position` | string | Page location: `top`, `bottom`, `right`, `middle` |
| `title` | string | Ad headline text |
| `link` | string | Destination URL |
| `displayed_link` | string | URL displayed to the user |
| `tracking_link` | string | Google Ads click-tracking URL |
| `description` | string | Ad body copy |
| `source` | string | Advertiser name |
| `extensions[]` | string[] | Ad extensions (callouts, structured snippets) |
| `sitelinks[]` | object[] | Additional links (see below) |
| `thumbnail` | string | Image thumbnail URL (hotel, travel, some display ads) |
| `price` | string | Displayed price (hotel, product ads) |
| `extracted_price` | float | Numeric price value |
| `rating` | float | Star rating (hotel, local) |
| `reviews` | int | Review count |
| `phone` | string | Click-to-call phone number |
| `links[]` | object[] | Location/map links (mobile ads) |
| `vehicles_for_sale[]` | object[] | Vehicle listing ads (see below) |

### `sitelinks[]` Object

| Field | Type | Description |
|-------|------|-------------|
| `title` | string | Sitelink title |
| `link` | string | Sitelink URL |
| `snippets[]` | string[] | Descriptions under the sitelink |

### `vehicles_for_sale[]` Object

Appears when query triggers vehicle ads (e.g., "2019 suvs for sale"):

| Field | Type | Description |
|-------|------|-------------|
| `title` | string | Vehicle name (e.g., "2019 Hyundai Tucson SE") |
| `thumbnail` | string | Vehicle image URL |
| `price` | string | Display price |
| `extracted_price` | float | Numeric price |
| `condition` | string | "Used" or "New" |
| `mileage` | string | Display mileage (e.g., "87k mi") |
| `extracted_mileage` | int | Numeric mileage |
| `dealership` | string | Dealer name |
| `location` | string | City/area |
| `link` | string | Listing URL |

### `links[]` Object (Bottom/Mobile Ads)

| Field | Type | Description |
|-------|------|-------------|
| `text` | string | Location info (distance, address, hours) |
| `tracking_link` | string | Click-tracking URL |
| `image` | string | Map image URL |

---

## Shopping Results Schema

### `shopping_results[]` — Full Field Reference

| Field | Type | Description |
|-------|------|-------------|
| `position` | int | Position in the shopping carousel |
| `block_position` | string | Usually `top` |
| `title` | string | Product name |
| `link` | string | Product page URL |
| `source` | string | Retailer name |
| `price` | string | Display price |
| `extracted_price` | float | Numeric price |
| `old_price` | string | Original/strikethrough price (sales) |
| `extracted_old_price` | float | Numeric original price |
| `rating` | float | Star rating |
| `reviews` | int | Number of reviews |
| `reviews_original` | string | Reviews as displayed (e.g., "1k+") |
| `shipping` | string | Shipping info (e.g., "Free shipping") |
| `thumbnail` | string | Product image URL |
| `extensions[]` | string[] | Product attributes (color, material, size, etc.) |
| `badge` | string | Special badge (e.g., "SALE", "SPONSORED") |

---

## Local Ads Schema

### `local_ads` Object

| Field | Type | Description |
|-------|------|-------------|
| `title` | string | Summary heading (e.g., "40+ plumbers nearby") |
| `link` | string | Google local services URL |
| `serpapi_link` | string | SerpApi link to `engine=google_local_services` |
| `see_more_text` | string | "More plumbers in [area]" |
| `badge` | string | Section badge |
| `ads[]` | object[] | Individual service provider ads |

### `local_ads.ads[]` Object

| Field | Type | Description |
|-------|------|-------------|
| `title` | string | Business name |
| `link` | string | Business profile URL |
| `rating` | float | Star rating |
| `badge` | string | Trust badge (e.g., "GOOGLE GUARANTEED", "GOOGLE SCREENED") |
| `service_area` | string | Service area (e.g., "Serves Dracut") |
| `hours` | string | Operating hours (e.g., "Open 24/7", "Open now") |
| `years_in_business` | string | Tenure (e.g., "22 years in business") |
| `phone` | string | Phone number |

---

## Ads Transparency Center

**Engine:** `google_ads_transparency_center`

### Parameters — Complete Reference

| Parameter | Required | Type | Description |
|-----------|----------|------|-------------|
| `advertiser_id` | Conditional | string | Google Advertiser ID (prefix `AR`). Comma-separate for multiple. Required if `text` not set |
| `text` | Conditional | string | Free-text/domain search. Required if `advertiser_id` not set |
| `platform` | No | string | Filter: `SEARCH`, `YOUTUBE`, `SHOPPING`, `MAPS`, `PLAY` |
| `political_ads` | No | boolean | `true` for political ads only. Requires `region` |
| `region` | No | string | Numeric region code (e.g., `2840` for US). See Regions section |
| `start_date` | No | string | Start date `YYYYMMDD` |
| `end_date` | No | string | End date `YYYYMMDD`. For single day: set to start + 1 day |
| `creative_format` | No | string | Filter: `text`, `image`, `video` |
| `num` | No | int | Results per page (default 40, max 100) |
| `next_page_token` | No | string | Pagination token |
| `no_cache` | No | boolean | Force fresh results |
| `async` | No | boolean | Submit and retrieve later |
| `api_key` | Yes | string | SerpApi key |

### Response Schema

```json
{
  "search_metadata": { "id": "...", "status": "Success", ... },
  "search_parameters": { "engine": "google_ads_transparency_center", ... },
  "search_information": { "total_results": 200 },
  "ad_creatives": [
    {
      "advertiser_id": "AR17828074650563772417",
      "advertiser": "Tesla Inc.",
      "ad_creative_id": "CR04179139827687489537",
      "format": "text",
      "target_domain": "tesla.com",
      "image": "https://tpc.googlesyndication.com/archive/simgad/...",
      "width": 380,
      "height": 239,
      "first_shown": 1691712612,
      "last_shown": 1696917405,
      "details_link": "https://adstransparency.google.com/advertiser/.../creative/...",
      "serpapi_details_link": "https://serpapi.com/search.json?engine=google_ads_transparency_center_ad_details&..."
    }
  ],
  "serpapi_pagination": {
    "next_page_token": "CgoAP7zn5UyV...",
    "next": "https://serpapi.com/search.json?..."
  }
}
```

---

## Ad Details

**Engine:** `google_ads_transparency_center_ad_details`

### Parameters — Complete Reference

| Parameter | Required | Type | Description |
|-----------|----------|------|-------------|
| `advertiser_id` | Yes | string | Google Advertiser ID |
| `creative_id` | Yes | string | Google Creative ID (prefix `CR`) |
| `region` | No | string | Numeric region code |
| `no_cache` | No | boolean | Force fresh results |
| `async` | No | boolean | Submit and retrieve later |
| `api_key` | Yes | string | SerpApi key |

### Response — Text Format Ad

```json
{
  "search_information": {
    "format": "text",
    "last_shown": 1755907200,
    "region_name": "anywhere",
    "more_ads_by_advertiser": "https://adstransparency.google.com/advertiser/...",
    "regions": [
      { "region": 2586, "region_name": "Pakistan", "last_shown": 1755820800 },
      { "region": 2276, "region_name": "Germany", "first_shown": 1703376000, "last_shown": 1755561600 }
    ]
  },
  "ad_creatives": [
    {
      "title": "Spaceship",
      "headline": "Spaceship.com Official Website - Connect Your Digital World",
      "snippet": "Propel your business into the digital frontier...",
      "visible_link": "www.spaceship.com/",
      "advertiser_logo": "https://tpc.googlesyndication.com/simgad/...",
      "advertiser_logo_alt": "Spaceship logo",
      "sitelink_texts": ["Free Domain Privacy", "Domain Name Registration", "Domain Price List"]
    }
  ]
}
```

### Response — Image Format Ad

```json
{
  "search_information": {
    "format": "image",
    "last_shown": 1755475200,
    "regions": [...]
  },
  "ad_creatives": [
    {
      "call_to_action": "Secure Your Website\nWith SSL",
      "snippet": "Buy SSL Certificates from $5.99 per yr",
      "link": "https://www.namecheap.com/security/ssl-certificates/",
      "image": "https://tpc.googlesyndication.com/archive/sadbundle/.../image.jpeg",
      "advertiser_logo": "https://tpc.googlesyndication.com/archive/sadbundle/.../logo.png"
    }
  ]
}
```

### Response — Video Format Ad

```json
{
  "ad_creatives": [
    {
      "call_to_action": "Learn More",
      "headline": "Product Launch Video",
      "snippet": "Watch our latest...",
      "link": "https://example.com",
      "video": "https://tpc.googlesyndication.com/archive/.../video.mp4",
      "advertiser_logo": "https://tpc.googlesyndication.com/..."
    }
  ]
}
```

---

## Transparency Center Regions

Common region codes (non-exhaustive — see SerpApi docs for full list):

| Code | Region |
|------|--------|
| `2840` | United States |
| `2826` | United Kingdom |
| `2276` | Germany |
| `2250` | France |
| `2124` | Canada |
| `2036` | Australia |
| `2392` | Japan |
| `2356` | India |
| `2076` | Brazil |

Omit `region` to search globally ("anywhere").

## Finding Advertiser IDs

1. Visit `https://adstransparency.google.com`
2. Search for the brand/company
3. The advertiser ID is in the URL: `adstransparency.google.com/advertiser/AR12345678901234567890`
4. Or use the `text` parameter in the API as a domain/keyword search to discover advertiser IDs from `ad_creatives[].advertiser_id`
