---
name: serp-google-hotels
description: >
  Foundational skill for the SerpApi Google Hotels API — search hotels and vacation rentals,
  get property details, read reviews, and autocomplete hotel queries. Use when: (1) searching
  for hotels or vacation rentals in a destination, (2) comparing hotel prices, ratings,
  and amenities, (3) getting detailed property information (address, phone, rooms, pricing
  from multiple sources), (4) reading and paginating hotel reviews with category filtering,
  (5) filtering hotels by price range, star rating, brands, amenities, or property type,
  (6) sorting results by price, rating, or review count, (7) searching vacation rentals with
  bedroom/bathroom filters, (8) autocompleting hotel names or destinations, (9) tracking hotel
  prices over time, (10) any task involving Google Hotels data through SerpApi. This is the
  base Google Hotels skill — specialized skills may reference it for travel planning, hotel
  comparison, or accommodation recommendation workflows.
metadata: {"openclaw": {"emoji": "🏨", "requires": {"env": ["SERPAPI_KEY"]}, "primaryEnv": "SERPAPI_KEY"}}
---

# SerpApi Google Hotels

Search hotels and vacation rentals, get property details, read reviews, and autocomplete destinations through SerpApi's structured JSON API. Four engines cover all Google Hotels data needs.

## Setup

Requires `SERPAPI_KEY` environment variable. All requests are GET to `https://serpapi.com/search` with `api_key` parameter.

## Engines Overview

| Engine | Purpose | Key Parameters |
|--------|---------|----------------|
| `google_hotels` | Search hotels/vacation rentals, get property details | `q`, `check_in_date`, `check_out_date` |
| `google_hotels_reviews` | Read reviews for a specific property | `property_token` |
| `google_hotels_autocomplete` | Autocomplete hotel names and destinations | `q` |

Property details are accessed via `google_hotels` engine with `property_token` parameter (not a separate engine).

---

## 1. Hotel Search

### Basic Search

```bash
curl -s "https://serpapi.com/search?engine=google_hotels&q=hotels+in+Paris&check_in_date=2026-06-01&check_out_date=2026-06-05&api_key=$SERPAPI_KEY"
```

**Required parameters:**

| Parameter | Description |
|-----------|-------------|
| `q` | Search query (destination, hotel name, etc.) |
| `check_in_date` | Check-in date in `YYYY-MM-DD` format |
| `check_out_date` | Check-out date in `YYYY-MM-DD` format |

**Optional parameters:**

| Parameter | Default | Description |
|-----------|---------|-------------|
| `gl` | `us` | Country code (e.g., `us`, `uk`, `fr`) |
| `hl` | `en` | Language code (e.g., `en`, `es`, `fr`) |
| `currency` | `USD` | Currency code for prices. See [Google Travel Currencies](https://serpapi.com/google-travel-currencies) |
| `adults` | `2` | Number of adults |
| `children` | `0` | Number of children |
| `children_ages` | — | Comma-separated ages (1–17). Count must match `children`. e.g., `5,8,10` |

### Sorting

| `sort_by` value | Sort Order |
|-----------------|------------|
| _(omit)_ | Relevance (default) |
| `3` | Lowest price |
| `8` | Highest rating |
| `13` | Most reviewed |

### Filtering

**Price:**

| Parameter | Description |
|-----------|-------------|
| `min_price` | Minimum nightly price |
| `max_price` | Maximum nightly price |

**Rating:**

| `rating` value | Minimum Rating |
|----------------|----------------|
| `7` | 3.5+ |
| `8` | 4.0+ |
| `9` | 4.5+ |

**Hotel-only filters** (not available for vacation rentals):

| Parameter | Description |
|-----------|-------------|
| `hotel_class` | Star rating. Values: `2`, `3`, `4`, `5`. Comma-separated for multiple: `3,4,5` |
| `brands` | Brand IDs from `brands[]` in response. Comma-separated: `33,67,101` |
| `free_cancellation` | `true` to show only free cancellation results |
| `special_offers` | `true` to show only results with special offers |
| `eco_certified` | `true` to show only eco-certified results |

**Property types & amenities:**

| Parameter | Description |
|-----------|-------------|
| `property_types` | Property type IDs. Comma-separated. See [Hotels Property Types](https://serpapi.com/google-hotels-property-types) or [Vacation Rentals Property Types](https://serpapi.com/google-vacation-rentals-property-types) |
| `amenities` | Amenity IDs. Comma-separated. See [Hotels Amenities](https://serpapi.com/google-hotels-amenities) or [Vacation Rentals Amenities](https://serpapi.com/google-vacation-rentals-amenities) |

### Vacation Rentals Search

Add `vacation_rentals=true` to switch from hotels to vacation rentals. Two additional filters are available:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `vacation_rentals` | — | Set `true` for vacation rental results |
| `bedrooms` | `0` | Minimum number of bedrooms |
| `bathrooms` | `0` | Minimum number of bathrooms |

```bash
curl -s "https://serpapi.com/search?engine=google_hotels&q=Costa+Rica+Beach&check_in_date=2026-06-01&check_out_date=2026-06-08&vacation_rentals=true&bedrooms=2&sort_by=3&max_price=200&api_key=$SERPAPI_KEY"
```

### Search Response Structure

The response contains:

- **`brands[]`** — Available hotel brands with `id` and `name` (use for `brands` filter)
- **`ads[]`** — Sponsored/ad properties
- **`properties[]`** — Main search results

**Each property in `properties[]`:**

| Field | Type | Description |
|-------|------|-------------|
| `type` | String | `"hotel"` or `"vacation rental"` |
| `name` | String | Property name |
| `description` | String | Short description |
| `property_token` | String | Token for property details and reviews |
| `serpapi_property_details_link` | String | Direct link to property details |
| `gps_coordinates` | Object | `{ latitude, longitude }` |
| `check_in_time` / `check_out_time` | String | e.g., `"3:00 PM"` / `"12:00 PM"` |
| `rate_per_night.lowest` | String | Formatted price (e.g., `"$149"`) |
| `rate_per_night.extracted_lowest` | Number | Numeric price value |
| `rate_per_night.before_taxes_fees` | String | Price before taxes |
| `total_rate` | Object | Same structure as `rate_per_night` for total stay |
| `prices[]` | Array | Prices from multiple booking sources |
| `nearby_places[]` | Array | Nearby POIs with transport type and duration |
| `hotel_class` / `extracted_hotel_class` | String/Number | Star rating (e.g., `"5-star hotel"` / `5`) |
| `overall_rating` | Number | Rating out of 5 |
| `reviews` | Number | Total review count |
| `location_rating` | Number | Location score |
| `amenities[]` | Array | List of amenity strings |
| `images[]` | Array | `{ thumbnail, original_image }` |
| `reviews_breakdown[]` | Array | Category reviews with `category_token` for filtering |
| `eco_certified` | Boolean | Whether property is eco-certified |
| `serpapi_google_hotels_reviews_link` | String | Direct link to reviews |

### Pagination

Use `next_page_token` from the response as the `next_page_token` parameter in the next request.

---

## 2. Property Details

Pass `property_token` to the `google_hotels` engine along with other search parameters to get full property details.

```bash
curl -s "https://serpapi.com/search?engine=google_hotels&q=Bali+Resorts&check_in_date=2026-06-01&check_out_date=2026-06-05&property_token=TOKEN_HERE&api_key=$SERPAPI_KEY"
```

**Property detail response includes everything from search results PLUS:**

| Field | Type | Description |
|-------|------|-------------|
| `address` | String | Full address |
| `phone` | String | Phone number |
| `phone_link` | String | `tel:` link |
| `link` | String | Property website |
| `directions` | String | Google Maps directions URL |
| `featured_prices[]` | Array | Detailed prices per source with room types, images, benefits |
| `typical_price_range` | String | e.g., `"$120 – $180"` |
| `amenities_detailed.groups[]` | Array | Grouped amenities with titles and items |

**Featured prices include room-level detail:**

```json
{
  "source": "Booking.com",
  "official": false,
  "rooms": [
    {
      "name": "King Room with Garden View",
      "images": [...],
      "num_guests": 2,
      "rate_per_night": { "lowest": "$180", "extracted_lowest": 180 }
    }
  ],
  "benefits": "Book with Booking.com to get: Free breakfast"
}
```

---

## 3. Reviews

### Fetch Reviews

```bash
curl -s "https://serpapi.com/search?engine=google_hotels_reviews&property_token=TOKEN_HERE&api_key=$SERPAPI_KEY"
```

**Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `property_token` | Yes | From property search results |
| `hl` | No | Language code |
| `sort_by` | No | `1` Most helpful (default), `2` Most recent, `3` Highest score, `4` Lowest score |
| `source_number` | No | Filter by source. `0` All (default), `-1` Google only. Property-specific source numbers from `other_reviews` in property details |
| `category_token` | No | Filter by category. Tokens from `reviews_breakdown[]` in search results |
| `next_page_token` | No | Pagination token |

### Review Response Structure

**Each review in `reviews[]`:**

| Field | Type | Description |
|-------|------|-------------|
| `user.name` | String | Reviewer name |
| `user.link` | String | Reviewer profile URL |
| `source` | String | Review source (e.g., `"Google"`, `"Tripadvisor"`) |
| `rating` | Number | Rating given (1–5) |
| `best_rating` | Number | Maximum possible rating (usually 5) |
| `date` | String | Relative date (e.g., `"2 months ago"`) |
| `snippet` | String | Full review text |
| `subratings` | Object | Category ratings: `{ rooms, service, location }` |
| `hotel_highlights[]` | Array | e.g., `["Luxury", "Great value"]` |
| `attributes[]` | Array | `{ name, snippet }` — specific aspect feedback |
| `response` | Object | Hotel's reply: `{ date, snippet }` |

### Pagination

Use `serpapi_pagination.next_page_token` as `next_page_token` in the next request. Follow `serpapi_pagination.next` URL directly as a convenience.

### Category-Filtered Reviews

Use `category_token` from `reviews_breakdown[]` in the property search results:

```bash
curl -s "https://serpapi.com/search?engine=google_hotels_reviews&property_token=TOKEN&category_token=CATEGORY_TOKEN&api_key=$SERPAPI_KEY"
```

Categories are property-specific (e.g., Property, Service, Nature, Food, Cleanliness).

---

## 4. Autocomplete

Get hotel name and destination suggestions as the user types.

```bash
curl -s "https://serpapi.com/search?engine=google_hotels_autocomplete&q=day+inn&api_key=$SERPAPI_KEY"
```

**Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | Yes | Search query |
| `gl` | No | Country code |
| `hl` | No | Language code |
| `currency` | No | Currency for generated links (default: `USD`) |

**Each suggestion in `suggestions[]`:**

| Field | Type | Description |
|-------|------|-------------|
| `value` | String | Suggestion text |
| `type` | String | `"accommodation"` or similar |
| `location` | String | Address (if specific property) |
| `property_token` | String | Token for specific properties (if available) |
| `kgmid` | String | Knowledge Graph ID |
| `data_cid` | String | CID for Google Local |
| `serpapi_google_hotels_link` | String | Direct SerpApi search link |

---

## Common Workflows

### Find Cheapest Hotels in a City

```bash
curl -s "https://serpapi.com/search?engine=google_hotels&q=hotels+in+Tokyo&check_in_date=2026-07-01&check_out_date=2026-07-05&sort_by=3&max_price=150&api_key=$SERPAPI_KEY"
```

### Compare Prices Across Booking Sites

1. Search for properties to find `property_token`
2. Get property details to see `featured_prices[]` with per-source pricing and room options
3. Compare `rate_per_night.extracted_lowest` across sources

### Get All Reviews for a Property

1. Fetch first page: `engine=google_hotels_reviews&property_token=TOKEN`
2. Read `serpapi_pagination.next_page_token`
3. Loop with `next_page_token` until no pagination token returned

### Monitor Hotel Prices

Run the same search query periodically with consistent parameters. Compare `properties[].rate_per_night.extracted_lowest` across runs.

### Find Specific Property by Name

1. Autocomplete: `engine=google_hotels_autocomplete&q=Hilton+Bali`
2. Get `property_token` from matching suggestion
3. Property details: `engine=google_hotels&property_token=TOKEN&q=...&check_in_date=...&check_out_date=...`

## Error Handling

| Issue | Solution |
|-------|----------|
| `search_metadata.status` is `"Error"` | Check `error` field for details |
| Empty `properties[]` | Broaden search, check dates, or adjust filters |
| No `property_token` in autocomplete | Suggestion is a general query, not a specific property |
| Missing `featured_prices[]` | Only available in property detail requests (with `property_token`) |
| Cache: `no_cache=true` | Forces fresh results (costs 1 credit). Don't combine with `async` |

## Detailed Reference

For complete JSON response examples, property type/amenity ID lists, and extended field documentation: see [references/api-reference.md](references/api-reference.md).
