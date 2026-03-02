# SerpApi Google Maps — API Reference

Complete parameter and response reference for all five Google Maps engines.

## Table of Contents

1. [Google Maps Search Engine](#google-maps-search-engine)
2. [Google Maps Place Details](#google-maps-place-details)
3. [Google Maps Reviews Engine](#google-maps-reviews-engine)
4. [Google Maps Photos Engine](#google-maps-photos-engine)
5. [Google Maps Posts Engine](#google-maps-posts-engine)
6. [Common SerpApi Parameters](#common-serpapi-parameters)

---

## Google Maps Search Engine

**Engine:** `google_maps`  
**Endpoint:** `GET https://serpapi.com/search?engine=google_maps`

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | Yes (when `type=search`) | Search query. Supports anything typed into Google Maps. |
| `type` | Yes (unless using `place_id`/`data_cid`) | `search` for local results, `place` for place details |
| `ll` | No | GPS origin: `@LAT,LON,ZOOMz` or `@LAT,LON,HEIGHTm`. Zoom: `3z`–`30z`. Height: `1m`–`15028132m`. |
| `location` | No | Named location (e.g., "Austin, TX"). Requires `z` or `m`. Can't use with `ll`, `lat`, `lon`. |
| `lat` | No | GPS latitude. Requires `lon`. Requires `z` or `m`. Can't use with `ll` or `location`. |
| `lon` | No | GPS longitude. Requires `lat`. Requires `z` or `m`. Can't use with `ll` or `location`. |
| `z` | No | Zoom level (3–30). Required with `location` or `lat`/`lon` (unless `m` is set). |
| `m` | No | Map height in meters (1–15028132). Alternative to `z`. |
| `nearby` | No | `true` to force results closer to specified location. Recommended with "near me" queries. |
| `place_id` | No | Google Place ID (`ChIJ...`). Fetches place details. Can't use with `data_cid`. |
| `data_cid` | No | Google CID (large integer). Fetches place details. Can't use with `place_id`. |
| `data` | No | Deprecated — use `place_id` or `data_cid` instead. Raw data filter string. |
| `start` | No | Pagination offset. Default `0`. Increment by 20. Max recommended: `100`. |
| `hl` | No | Language code (e.g., `en`, `es`, `fr`). |
| `gl` | No | Country code (e.g., `us`, `uk`). Affects Place Results only. |
| `google_domain` | No | Google domain (default: `google.com`). |

### Search Response (`type=search`)

#### `local_results[]`

| Field | Type | Always Present | Description |
|-------|------|----------------|-------------|
| `position` | int | Yes | Result index |
| `title` | string | Yes | Business name |
| `place_id` | string | Yes | Google Place ID |
| `data_id` | string | Yes | SerpApi data ID (use for reviews/photos/posts) |
| `data_cid` | string | Yes | Google CID |
| `reviews_link` | string | Yes | SerpApi URL for reviews |
| `photos_link` | string | Yes | SerpApi URL for photos |
| `gps_coordinates` | object | Yes | `{latitude: float, longitude: float}` |
| `place_id_search` | string | Yes | SerpApi URL for place details |
| `provider_id` | string | Yes | Google provider path (e.g., `/g/11b6bn9665`) |
| `rating` | float | No | Average rating (1.0–5.0) |
| `reviews` | int | No | Total review count |
| `price` | string | No | Price level: `$`, `$$`, `$$$`, `$$$$` |
| `type` | string | No | Primary business category |
| `types` | string[] | No | All business categories |
| `type_id` | string | No | Primary category ID (e.g., `coffee_shop`) |
| `type_ids` | string[] | No | All category IDs |
| `address` | string | No | Full street address |
| `open_state` | string | No | Open/closed status text |
| `hours` | string | No | Hours summary text |
| `operating_hours` | object | No | `{monday: "7 AM–6 PM", ...}` |
| `phone` | string | No | Phone number |
| `website` | string | No | Website URL |
| `description` | string | No | Business description |
| `service_options` | object | No | `{dine_in, takeout, delivery, curbside_pickup}` — booleans |
| `thumbnail` | string | No | Thumbnail image URL |
| `serpapi_thumbnail` | string | No | SerpApi-proxied thumbnail URL |

#### `ads[]`

Same schema as `local_results[]`. Represents sponsored/advertisement results.

#### `search_information`

| Field | Type | Description |
|-------|------|-------------|
| `local_results_state` | string | Status of search results |
| `query_displayed` | string | Query as interpreted by Google |

#### `serpapi_pagination`

| Field | Type | Description |
|-------|------|-------------|
| `next` | string | URL for next page of results |
| `current_start` | int | Current offset |

### Hotel Results

When searching for hotels, `local_results[]` may include additional fields:

| Field | Type | Description |
|-------|------|-------------|
| `price` | string | Price as displayed (e.g., "$150") |
| `rate_per_night` | object | `{lowest: string, extracted_lowest: float, before_taxes_fees: string, extracted_before_taxes_fees: float}` |
| `total_rate` | object | `{lowest: string, extracted_lowest: float, before_taxes_fees: string, extracted_before_taxes_fees: float}` |
| `amenities` | string[] | Hotel amenities list |
| `check_in_time` | string | Check-in time |
| `check_out_time` | string | Check-out time |
| `overall_rating` | float | Overall hotel rating |
| `nearby_places` | array | Nearby attractions/POIs |

**Date filter via `data` param:**

```
data=!4m6!2m5!5m3!5m1!1sYYYY-MM-DD!8m2!3dLAT!4dLON
```

Example: `data=!4m6!2m5!5m3!5m1!1s2026-03-15!8m2!3d40.7128!4d-74.0060`

---

## Google Maps Place Details

**Engine:** `google_maps` with `type=place`, `place_id`, or `data_cid`

### `place_results` Object

Includes all fields from `local_results[]` item above, plus:

| Field | Type | Description |
|-------|------|-------------|
| `menu` | object | `{link: string, source: string}` |
| `order_online_link` | string | Online ordering URL |
| `booking_link` | string | Reservation URL |
| `located_in` | string | Parent location name |
| `plus_code` | string | Google Plus Code |
| `extensions` | array | Array of objects, each containing a category and values. Categories include: `highlights`, `popular_for`, `accessibility`, `offerings`, `dining_options`, `amenities`, `atmosphere`, `crowd`, `payments`, `children`, `parking`, `planning`. |
| `unsupported_extensions` | array | Same format as `extensions` — less commonly available. |
| `images` | array | `[{title: string, thumbnail: string}]` — categorized image galleries |
| `user_reviews.summary` | array | `[{snippet: string}]` — review highlights |
| `user_reviews.most_relevant` | array | Full review objects (see below) |
| `people_also_search_for` | array | `[{search_term: string, local_results: [...]}]` |
| `similar_places_nearby` | array | Nearby alternatives with basic info |

### User Review Object (in `user_reviews.most_relevant[]`)

| Field | Type | Description |
|-------|------|-------------|
| `username` | string | Reviewer name |
| `rating` | int | Rating (1–5) |
| `contributor_id` | string | Google contributor ID |
| `description` | string | Review text |
| `date` | string | Relative date ("a month ago", "2 weeks ago") |
| `images` | array | `[{thumbnail: string}]` — review photos |

---

## Google Maps Reviews Engine

**Engine:** `google_maps_reviews`  
**Endpoint:** `GET https://serpapi.com/search?engine=google_maps_reviews`

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `data_id` | One of `data_id` or `place_id` | Google Maps data ID (hex format) |
| `place_id` | One of `data_id` or `place_id` | Google Place ID (`ChIJ...`) |
| `hl` | No | Language code (default: `en`) |
| `sort_by` | No | `qualityScore` (default), `newestFirst`, `ratingHigh`, `ratingLow` |
| `topic_id` | No | Filter by topic ID (from `topics[]`). Can't use with `query`. |
| `query` | No | Text filter for reviews. Can't use with `topic_id`. |
| `num` | No | Results per page (1–20, default 10). First page without `next_page_token` always returns 8. |
| `next_page_token` | No | Pagination token from previous response. |

### Response

#### `place_info`

| Field | Type | Description |
|-------|------|-------------|
| `title` | string | Place name |
| `address` | string | Full address |
| `rating` | float | Average rating |
| `reviews` | int | Total review count |
| `type` | string | Place type |

#### `topics[]`

| Field | Type | Description |
|-------|------|-------------|
| `keyword` | string | Topic keyword (e.g., "coffee", "wifi") |
| `mentions` | int | Number of reviews mentioning this topic |
| `id` | string | Topic ID (use with `topic_id` parameter) |

#### `reviews[]`

| Field | Type | Description |
|-------|------|-------------|
| `user` | object | `{name, link, thumbnail, reviews, photos, contributor_id, local_guide}` |
| `rating` | int | Rating (1–5) |
| `date` | string | Relative date |
| `iso_date` | string | ISO 8601 date |
| `iso_date_of_last_edit` | string | ISO 8601 date (if review was edited) |
| `snippet` | string | Review text |
| `likes` | int | Number of likes |
| `images` | array | `[{thumbnail: string}]` — review photos |
| `response_from_owner` | object | `{title, date, iso_date, iso_date_of_last_edit, snippet}` |
| `details` | array | Structured review details (e.g., meal type, price per person) |

---

## Google Maps Photos Engine

**Engine:** `google_maps_photos`  
**Endpoint:** `GET https://serpapi.com/search?engine=google_maps_photos`

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `data_id` | Yes | Google Maps data ID (hex format) |
| `hl` | No | Language code (default: `en`) |
| `category_id` | No | Filter by category ID (from `categories[]`) |
| `next_page_token` | No | Pagination token. 20 results per page. |

### Response

#### `categories[]`

| Field | Type | Description |
|-------|------|-------------|
| `title` | string | Category name (e.g., "All", "Menu", "Food & drink", "Vibe", "By owner") |
| `id` | string | Category ID for filtering |

#### `photos[]`

| Field | Type | Description |
|-------|------|-------------|
| `image` | string | Full-resolution image URL |
| `thumbnail` | string | Thumbnail URL |
| `date` | string | Date photo was uploaded |
| `source` | string | Photo source info |
| `user` | object | `{name, link, thumbnail}` — uploader info |
| `description` | string | Photo description (if available) |

---

## Google Maps Posts Engine

**Engine:** `google_maps_posts`  
**Endpoint:** `GET https://serpapi.com/search?engine=google_maps_posts`

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `data_id` | Yes | Google Maps data ID (hex format) |
| `next_page_token` | No | Pagination token. 10 results per page. |

### Response

#### `posts[]`

| Field | Type | Description |
|-------|------|-------------|
| `position` | int | Post index |
| `title` | string | Post title/headline |
| `description` | string | Post body text |
| `images` | array | `[{thumbnail: string}]` — post images |
| `date` | string | Post date |
| `link` | string | Link URL (if post links somewhere) |
| `event` | object | Event details `{title, date, description}` (for event posts) |

---

## Common SerpApi Parameters

These work across all Google Maps engines:

| Parameter | Description |
|-----------|-------------|
| `api_key` | **Required.** Your SerpApi key. |
| `engine` | **Required.** `google_maps`, `google_maps_reviews`, `google_maps_photos`, or `google_maps_posts`. |
| `no_cache` | `true` to force fresh results (costs a credit). Don't combine with `async`. |
| `async` | `true` for async search (retrieve later via Searches Archive API). Don't combine with `no_cache`. |
| `zero_trace` | Enterprise only. `true` to skip storing search data on SerpApi servers. |
| `output` | `json` (default) or `html`. |
| `json_restrictor` | Limit response fields for smaller payloads. |
