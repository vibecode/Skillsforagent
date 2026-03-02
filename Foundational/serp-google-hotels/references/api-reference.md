# SerpApi Google Hotels — API Reference

Comprehensive reference for all Google Hotels API engines, parameters, and response schemas.

## Table of Contents

1. [Hotel Search Parameters](#hotel-search-parameters)
2. [Hotel Search Response](#hotel-search-response)
3. [Property Details Response](#property-details-response)
4. [Reviews API Parameters & Response](#reviews-api)
5. [Autocomplete API Parameters & Response](#autocomplete-api)
6. [Filter ID Discovery](#filter-id-discovery)
7. [Common Brand IDs](#common-brand-ids)

---

## Hotel Search Parameters

All parameters for `engine=google_hotels`.

| Parameter | Required | Type | Description |
|-----------|----------|------|-------------|
| `q` | Yes | String | Search query (city, region, hotel name) |
| `check_in_date` | Yes | String | `YYYY-MM-DD` format |
| `check_out_date` | Yes | String | `YYYY-MM-DD` format |
| `gl` | No | String | Country code (default: `us`) |
| `hl` | No | String | Language code (default: `en`) |
| `currency` | No | String | Currency code (default: `USD`) |
| `adults` | No | Integer | Number of adults (default: `2`) |
| `children` | No | Integer | Number of children (default: `0`) |
| `children_ages` | No | String | Comma-separated ages 1–17. Must match `children` count |
| `sort_by` | No | Integer | `3` Lowest price, `8` Highest rating, `13` Most reviewed |
| `min_price` | No | Integer | Minimum nightly price |
| `max_price` | No | Integer | Maximum nightly price |
| `rating` | No | Integer | `7` (3.5+), `8` (4.0+), `9` (4.5+) |
| `hotel_class` | No | String | Star rating: `2`,`3`,`4`,`5`. Comma-separated for multiple |
| `brands` | No | String | Brand IDs from response `brands[]`. Comma-separated |
| `free_cancellation` | No | Boolean | Hotels with free cancellation only |
| `special_offers` | No | Boolean | Hotels with special offers only |
| `eco_certified` | No | Boolean | Eco-certified hotels only |
| `property_types` | No | String | Property type IDs. Comma-separated |
| `amenities` | No | String | Amenity IDs. Comma-separated |
| `vacation_rentals` | No | Boolean | Switch to vacation rental results |
| `bedrooms` | No | Integer | Min bedrooms (vacation rentals only) |
| `bathrooms` | No | Integer | Min bathrooms (vacation rentals only) |
| `next_page_token` | No | String | Pagination token from previous response |
| `property_token` | No | String | Get property details instead of search results |
| `no_cache` | No | Boolean | Force fresh results (costs 1 credit) |
| `api_key` | Yes | String | SerpApi API key |

---

## Hotel Search Response

### Top-Level Structure

```json
{
  "search_metadata": { "status": "Success", ... },
  "search_parameters": { ... },
  "search_information": { "total_results": 15000 },
  "brands": [ ... ],
  "ads": [ ... ],
  "properties": [ ... ],
  "serpapi_pagination": { "next_page_token": "..." }
}
```

### `brands[]` Structure

```json
{
  "id": 33,
  "name": "Accor Live Limitless",
  "children": [
    { "id": 67, "name": "Banyan Tree" },
    { "id": 101, "name": "Grand Mercure" }
  ]
}
```

Brands can be nested (parent brand → sub-brands). Use `id` for the `brands` filter.

### `properties[]` Full Schema

```json
{
  "type": "hotel",
  "name": "Hilton Bali Resort",
  "description": "Short property description...",
  "logo": "https://...",
  "sponsored": true,
  "property_token": "ChcI...",
  "serpapi_property_details_link": "https://serpapi.com/search.json?...",
  "serpapi_google_hotels_reviews_link": "https://serpapi.com/search.json?...",
  "serpapi_google_hotels_photos_link": "https://serpapi.com/search.json?...",
  "gps_coordinates": { "latitude": -8.825, "longitude": 115.218 },
  "check_in_time": "3:00 PM",
  "check_out_time": "12:00 PM",
  "rate_per_night": {
    "lowest": "$149",
    "extracted_lowest": 149,
    "before_taxes_fees": "$135",
    "extracted_before_taxes_fees": 135
  },
  "total_rate": {
    "lowest": "$596",
    "extracted_lowest": 596,
    "before_taxes_fees": "$540",
    "extracted_before_taxes_fees": 540
  },
  "prices": [
    {
      "source": "Booking.com",
      "logo": "https://...",
      "num_guests": 2,
      "rate_per_night": { "lowest": "$180", "extracted_lowest": 180 }
    }
  ],
  "nearby_places": [
    {
      "name": "Airport Name",
      "transportations": [
        { "type": "Taxi", "duration": "29 min" }
      ]
    }
  ],
  "hotel_class": "5-star hotel",
  "extracted_hotel_class": 5,
  "overall_rating": 4.6,
  "reviews": 3614,
  "location_rating": 2.8,
  "reviews_breakdown": [
    {
      "name": "Service",
      "description": "Service",
      "total_mentioned": 599,
      "positive": 507,
      "negative": 74,
      "neutral": 18,
      "category_token": "DZ7RY...",
      "serpapi_link": "https://serpapi.com/search.json?..."
    }
  ],
  "amenities": ["Free Wi-Fi", "Pool", "Spa", "Beach access"],
  "images": [
    { "thumbnail": "https://...", "original_image": "https://..." }
  ],
  "eco_certified": true
}
```

### `ads[]` Structure

Same fields as `properties[]` but with simplified pricing:

```json
{
  "name": "Hotel Name",
  "source": "Booking.com",
  "source_icon": "https://...",
  "link": "https://...",
  "property_token": "Cgo...",
  "gps_coordinates": { "latitude": ..., "longitude": ... },
  "thumbnail": "https://...",
  "overall_rating": 4.8,
  "reviews": 117,
  "hotel_class": 4,
  "price": "$70",
  "extracted_price": 70,
  "amenities": ["Beach access", "Pool", "Kid-friendly"],
  "free_cancellation": true
}
```

---

## Property Details Response

When `property_token` is provided, the response includes a single property with extended fields.

### Additional Fields (Beyond Search Results)

```json
{
  "address": "Full street address",
  "directions": "https://maps.google.com/maps?...",
  "phone": "+62 361 773377",
  "phone_link": "tel:+62361773377",
  "link": "https://www.hotel-website.com/...",
  "typical_price_range": "$120 – $180",
  "featured_prices": [
    {
      "source": "Priceline",
      "logo": "https://...",
      "link": "https://...",
      "official": false,
      "rooms": [
        {
          "name": "King Room with Garden View - Non-Refundable",
          "images": ["https://..."],
          "link": "https://...",
          "num_guests": 2,
          "rate_per_night": {
            "lowest": "$180",
            "extracted_lowest": 180,
            "before_taxes_fees": "$165",
            "extracted_before_taxes_fees": 165
          },
          "total_rate": { ... }
        }
      ],
      "num_guests": 2,
      "rate_per_night": { ... },
      "total_rate": { ... },
      "benefits": "Book with Priceline to get these at no extra cost: Wi-Fi and parking"
    }
  ],
  "amenities_detailed": {
    "groups": [
      {
        "title": "Popular amenities",
        "list": [
          { "title": "Free Wi-Fi", "label": "In all rooms" },
          { "title": "Pool", "label": "2 outdoor pools" }
        ]
      }
    ]
  },
  "other_reviews": [
    {
      "source": "Tripadvisor",
      "source_number": 1,
      "rating": 4.5,
      "reviews": 2340
    }
  ]
}
```

The `official` flag on featured prices indicates the hotel's own website listing. The `other_reviews` array provides `source_number` values for filtering reviews by source.

---

## Reviews API

### Parameters (`engine=google_hotels_reviews`)

| Parameter | Required | Type | Description |
|-----------|----------|------|-------------|
| `property_token` | Yes | String | From search results |
| `hl` | No | String | Language code |
| `sort_by` | No | Integer | `1` Most helpful, `2` Most recent, `3` Highest, `4` Lowest |
| `source_number` | No | Integer | `0` All, `-1` Google, or property-specific numbers from `other_reviews` |
| `category_token` | No | String | From `reviews_breakdown[].category_token` |
| `next_page_token` | No | String | Pagination token |
| `api_key` | Yes | String | SerpApi API key |

### Response Structure

```json
{
  "search_metadata": { "status": "Success", ... },
  "search_parameters": { ... },
  "reviews": [
    {
      "user": {
        "name": "Reviewer Name",
        "link": "https://...",
        "thumbnail": "https://..."
      },
      "source": "Google",
      "source_icon": "https://...",
      "rating": 5,
      "best_rating": 5,
      "date": "2 months ago",
      "snippet": "Full review text...",
      "subratings": {
        "rooms": 5,
        "service": 5,
        "location": 5
      },
      "hotel_highlights": ["Luxury", "Great value"],
      "attributes": [
        { "name": "Rooms", "snippet": "Beds are so comfy!" },
        { "name": "Food & drinks", "snippet": "Great breakfast buffet" }
      ],
      "response": {
        "date": "2 months ago",
        "snippet": "Thank you for your review..."
      }
    }
  ],
  "serpapi_pagination": {
    "next_page_token": "...",
    "next": "https://serpapi.com/search.json?..."
  }
}
```

Reviews from third-party sources (Tripadvisor, etc.) include a `link` field at the review level pointing to the original review.

---

## Autocomplete API

### Parameters (`engine=google_hotels_autocomplete`)

| Parameter | Required | Type | Description |
|-----------|----------|------|-------------|
| `q` | Yes | String | Partial query text |
| `gl` | No | String | Country code |
| `hl` | No | String | Language code |
| `currency` | No | String | Currency for generated links (default: `USD`) |
| `api_key` | Yes | String | SerpApi API key |

### Response Structure

```json
{
  "suggestions": [
    {
      "position": 1,
      "value": "Days Inn",
      "type": "accommodation",
      "location": "4400 Connecticut Ave NW, Washington",
      "thumbnail": "https://...",
      "highlighted_words": ["washington", "dc"],
      "autocomplete_suggestion": "day inn washington dc",
      "kgmid": "/g/1hf8_s33q",
      "data_cid": "242587712928378716",
      "property_token": "ChgI3N7h...",
      "serpapi_google_hotels_link": "https://serpapi.com/search.json?...",
      "serpapi_link": "https://serpapi.com/search.json?..."
    }
  ]
}
```

Not all suggestions have `property_token` — generic query suggestions (e.g., "day inn hotel near me") only have `serpapi_google_hotels_link`. Specific property suggestions include `property_token`, `location`, `data_cid`, and `kgmid`.

---

## Filter ID Discovery

Property types and amenities use numeric IDs. Full lists are maintained by SerpApi:

- **Hotels property types:** https://serpapi.com/google-hotels-property-types
- **Hotels amenities:** https://serpapi.com/google-hotels-amenities
- **Vacation rentals property types:** https://serpapi.com/google-vacation-rentals-property-types
- **Vacation rentals amenities:** https://serpapi.com/google-vacation-rentals-amenities

These IDs may change over time. Always reference the live pages for the latest values.

### Common Hotels Amenity IDs (Non-Exhaustive)

| ID | Amenity |
|----|---------|
| `35` | Free Wi-Fi |
| `9` | Pool |
| `19` | Spa |
| `7` | Restaurant |
| `4` | Free parking |
| `6` | Fitness centre |
| `15` | Air conditioning |
| `1` | Bar |

### Common Hotels Property Type IDs (Non-Exhaustive)

| ID | Type |
|----|------|
| `17` | Hotel |
| `12` | Resort |
| `18` | Inn |
| `20` | Motel |
| `2` | Bed & breakfast |

---

## Common Brand IDs

Brand IDs are dynamic and vary by search location. Always use `brands[]` from the search response for accurate IDs. Example IDs from a Bali search:

| ID | Brand |
|----|-------|
| `33` | Accor Live Limitless |
| `223` | Archipelago International |
| `67` | Banyan Tree |
| `101` | Grand Mercure |

Brand IDs are nested: parent brand (e.g., Accor) contains `children[]` with sub-brands. Use any level's `id` for the `brands` filter parameter.
