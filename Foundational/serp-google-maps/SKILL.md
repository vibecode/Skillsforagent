---
name: serp-google-maps
description: >
  Foundational skill for SerpApi Google Maps API — search for local businesses,
  get place details, reviews, photos, and posts from Google Maps. Use when:
  (1) searching for businesses, restaurants, hotels, or services near a location,
  (2) getting detailed place information (hours, address, phone, website, ratings),
  (3) fetching Google Maps reviews for a place with sorting and filtering,
  (4) retrieving photos for a place by category,
  (5) getting business posts ("From the owner") for a place,
  (6) finding GPS coordinates, data IDs, or place IDs for locations,
  (7) discovering nearby businesses or services on Google Maps,
  (8) comparing local business ratings, prices, and reviews,
  (9) extracting hotel availability, pricing, or amenities from Google Maps.
  This is the base SerpApi Google Maps skill — specialized skills may reference
  it for local business research, review analysis, or location-based workflows.
metadata: {"openclaw": {"emoji": "🗺️", "requires": {"env": ["SERPAPI_KEY"]}, "primaryEnv": "SERPAPI_KEY"}}
---

# SerpApi Google Maps

Search for local businesses, get place details, reviews, photos, and posts from Google Maps via SerpApi's structured JSON API. Five engines cover all Google Maps data needs.

## Setup

Requires `SERPAPI_KEY` environment variable. All requests go to `https://serpapi.com/search` as GET requests with `api_key` parameter.

## Engines Overview

| Engine | Purpose | Key Parameters |
|--------|---------|----------------|
| `google_maps` | Search for places OR get place details | `q` + `type=search`, or `place_id`/`data_cid` |
| `google_maps_reviews` | Reviews for a place | `data_id` or `place_id` |
| `google_maps_photos` | Photos for a place | `data_id` |
| `google_maps_posts` | Business owner posts | `data_id` |

## Quick Reference

### 1. Search for Local Businesses

```bash
curl -s "https://serpapi.com/search?engine=google_maps&type=search&q=QUERY&ll=@LAT,LON,ZOOM&api_key=$SERPAPI_KEY"
```

**Required:** `type=search`, `q` (query — anything you'd type into Google Maps)

**Location (pick one approach):**
- `ll=@40.7455096,-74.0083012,14z` — GPS coordinates with zoom (`3z`–`23z`) or meters (`1m`–`15028132m`)
- `location=New York, NY` + `z=14` (or `m=10000`) — named location with zoom
- `lat=40.74` + `lon=-74.00` + `z=14` — separate lat/lon with zoom

**Tip:** Add `nearby=true` when using "near me" keywords in the query. Don't use `nearby` when the query already includes a city/state/zip.

**Localization:** `hl` (language code), `gl` (country code), `google_domain`

**Pagination:** `start=0` (default), increment by 20. Max recommended: `start=100` (page 6).

**Returns:** `local_results[]`, `ads[]`, `serpapi_pagination`, `search_information`

### 2. Get Place Details

```bash
# By place_id (preferred — no type param needed)
curl -s "https://serpapi.com/search?engine=google_maps&place_id=PLACE_ID&api_key=$SERPAPI_KEY"

# By data_cid (no type param needed)
curl -s "https://serpapi.com/search?engine=google_maps&data_cid=DATA_CID&api_key=$SERPAPI_KEY"
```

**Returns:** `place_results` object with title, rating, reviews, price, type, address, phone, website, hours, operating_hours, extensions, images, user_reviews, gps_coordinates, description, service_options, people_also_search_for, and more.

### 3. Get Reviews

```bash
curl -s "https://serpapi.com/search?engine=google_maps_reviews&data_id=DATA_ID&api_key=$SERPAPI_KEY"
```

**Required:** `data_id` or `place_id` (one of them)

**Optional:**
- `sort_by` — `qualityScore` (default), `newestFirst`, `ratingHigh`, `ratingLow`
- `topic_id` — filter by topic (IDs from `topics[]` in response)
- `query` — text filter (can't combine with `topic_id`)
- `hl` — language code
- `num` — results per page (1–20, default 10; first page without `next_page_token` always returns 8)
- `next_page_token` — for pagination

**Returns:** `place_info`, `topics[]`, `reviews[]` (with username, rating, date, description, images, response from owner)

### 4. Get Photos

```bash
curl -s "https://serpapi.com/search?engine=google_maps_photos&data_id=DATA_ID&api_key=$SERPAPI_KEY"
```

**Required:** `data_id`

**Optional:**
- `category_id` — filter by category (IDs from `categories[]` in response)
- `hl` — language code
- `next_page_token` — pagination (20 results per page)

**Returns:** `categories[]` (title + id), `photos[]` (image, date, source, description, thumbnail, user info)

### 5. Get Posts ("From the Owner")

```bash
curl -s "https://serpapi.com/search?engine=google_maps_posts&data_id=DATA_ID&api_key=$SERPAPI_KEY"
```

**Required:** `data_id`

**Optional:** `next_page_token` — pagination (10 results per page)

**Returns:** `posts[]` (title, description, images, date, link)

## Location Parameters

Multiple ways to specify search origin for `google_maps` engine:

| Approach | Parameters | Example |
|----------|-----------|---------|
| Raw `ll` string | `ll=@LAT,LON,ZOOMz` | `ll=@40.7455,-74.0083,14z` |
| Named location | `location` + `z` or `m` | `location=Austin, TX&z=12` |
| Separate coords | `lat` + `lon` + `z` or `m` | `lat=40.74&lon=-74.00&z=14` |

**Zoom levels:** `3` = world view, `14` = city level, `18`–`23` = street level. Higher values may work in some areas.

**Can't mix:** `ll` with `location`, `lat`, `lon`, `z`, or `m`.

## Identifying Places

Every local result includes multiple identifiers:

| Field | Format | Usage |
|-------|--------|-------|
| `place_id` | `ChIJ...` string | Google's stable place reference. Use with `place_id` param. |
| `data_id` | `0x...:0x...` hex string | SerpApi's internal ID. Use with `data_id` param (reviews, photos, posts). |
| `data_cid` | Large integer | Google CID. Use with `data_cid` param or `ludocid` in Google Local API. |

**Workflow:** Search → get `data_id` from results → use it for reviews/photos/posts.

Each result also includes ready-to-use SerpApi links:
- `reviews_link` — direct URL for reviews
- `photos_link` — direct URL for photos
- `place_id_search` — direct URL for place details

## Local Results Schema

Each item in `local_results[]`:

| Field | Type | Description |
|-------|------|-------------|
| `position` | int | Result index |
| `title` | string | Business name |
| `place_id` | string | Google Place ID |
| `data_id` | string | SerpApi data ID (for reviews/photos/posts) |
| `data_cid` | string | Google CID |
| `rating` | float | Average rating (1–5) |
| `reviews` | int | Review count |
| `price` | string | Price level (`$`, `$$`, `$$$`, `$$$$`) |
| `type` | string | Primary business type |
| `types` | string[] | All business types |
| `type_id` | string | Primary type ID |
| `type_ids` | string[] | All type IDs |
| `address` | string | Full address |
| `phone` | string | Phone number |
| `website` | string | Website URL |
| `description` | string | Business description |
| `open_state` | string | Current open/closed status |
| `hours` | string | Hours summary |
| `operating_hours` | object | Daily hours (monday–sunday) |
| `gps_coordinates` | object | `{latitude, longitude}` |
| `thumbnail` | string | Image URL |
| `service_options` | object | `{dine_in, takeout, delivery, curbside_pickup}` |
| `reviews_link` | string | SerpApi reviews URL |
| `photos_link` | string | SerpApi photos URL |
| `place_id_search` | string | SerpApi place details URL |

## Place Details Schema

The `place_results` object (from place lookup) includes everything in local results plus:

| Field | Type | Description |
|-------|------|-------------|
| `menu` | object | `{link, source}` — menu URL |
| `order_online_link` | string | Online ordering URL |
| `booking_link` | string | Reservation URL |
| `extensions` | array | Grouped highlights, accessibility, payments, etc. |
| `images` | array | `[{title, thumbnail}]` — categorized images |
| `user_reviews.summary` | array | Review snippet highlights |
| `user_reviews.most_relevant` | array | Full reviews with username, rating, date, description, images |
| `people_also_search_for` | array | Related place suggestions |
| `similar_places_nearby` | array | Nearby alternatives |
| `located_in` | string | Parent location (e.g., "Ace Hotel New York") |
| `plus_code` | string | Google Plus Code |

## Common Patterns

### Find Restaurants Near Coordinates

```bash
curl -s "https://serpapi.com/search?engine=google_maps&type=search&q=italian+restaurant&ll=@40.7455,-74.0083,14z&api_key=$SERPAPI_KEY"
```

### Get Full Details for a Place

```bash
# 1. Search first to find place_id
curl -s "https://serpapi.com/search?engine=google_maps&type=search&q=Stumptown+Coffee+New+York&api_key=$SERPAPI_KEY"

# 2. Use place_id from results
curl -s "https://serpapi.com/search?engine=google_maps&place_id=ChIJT2h1HKZZwokR0kgzEtsa03k&api_key=$SERPAPI_KEY"
```

### Collect All Reviews for a Place

```bash
# First page (always returns 8)
curl -s "https://serpapi.com/search?engine=google_maps_reviews&data_id=DATA_ID&sort_by=newestFirst&api_key=$SERPAPI_KEY"

# Subsequent pages using next_page_token from previous response
curl -s "https://serpapi.com/search?engine=google_maps_reviews&data_id=DATA_ID&sort_by=newestFirst&next_page_token=TOKEN&num=20&api_key=$SERPAPI_KEY"
```

### Search Hotels with Date Filters

Pass dates via the `data` parameter:

```
data=!4m6!2m5!5m3!5m1!1s2026-03-15!8m2!3d40.7128!4d-74.0060
```

Format: `!4m6!2m5!5m3!5m1!1s` + check-in date (YYYY-MM-DD) + `!8m2!3d` + lat + `!4d` + lon

Hotel results include `price`, `rate_per_night`, `total_rate`, `amenities`, `check_in_time`, `check_out_time`.

### Browse Photos by Category

```bash
# Get categories first
curl -s "https://serpapi.com/search?engine=google_maps_photos&data_id=DATA_ID&api_key=$SERPAPI_KEY"
# Response includes categories[]: [{title: "All", id: "CgIgAQ"}, {title: "Menu", id: "CgIYIQ"}, ...]

# Filter by category
curl -s "https://serpapi.com/search?engine=google_maps_photos&data_id=DATA_ID&category_id=CgIYIQ&api_key=$SERPAPI_KEY"
```

### "Near Me" Searches

```bash
# IMPORTANT: Use nearby=true with "near me" queries
curl -s "https://serpapi.com/search?engine=google_maps&type=search&q=coffee+near+me&ll=@40.7455,-74.0083,14z&nearby=true&api_key=$SERPAPI_KEY"
```

## Error Handling

- Check `search_metadata.status` — should be `"Success"`
- On error, `error` field contains the message
- Cache is 1h; use `no_cache=true` to force fresh results (costs a search credit)
- Don't combine `no_cache` and `async`
- Rate limits depend on your SerpApi plan
- Results are **not guaranteed** to be within the `ll` geographic area — use `nearby=true` for tighter locality
- When `place_id` or `data_cid` is used, `type` parameter is not required

## Detailed Reference

For complete parameter tables, all response fields, review topics schema, and hotel-specific fields: read [references/api-reference.md](references/api-reference.md).
