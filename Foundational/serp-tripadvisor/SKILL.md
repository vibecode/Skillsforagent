---
name: serp-tripadvisor
description: >
  Foundational skill for the SerpApi TripAdvisor API — search TripAdvisor for restaurants,
  hotels, attractions, destinations, and forums, then get detailed place information including
  reviews, menus, pricing, hours, and photos. Use when: (1) searching TripAdvisor for places
  by keyword, (2) finding restaurants, hotels, or things to do in a location, (3) getting
  detailed info about a TripAdvisor place (reviews, ratings, hours, menu, prices), (4) looking
  up hotel prices and booking options on TripAdvisor, (5) reading restaurant reviews, menus,
  and dining details, (6) exploring attractions with tours, tickets, and visitor highlights,
  (7) filtering TripAdvisor searches by category (restaurants, hotels, attractions, forums),
  (8) paginating through TripAdvisor search results, (9) any task involving TripAdvisor data
  through SerpApi. This is the base TripAdvisor skill — specialized skills may reference it
  for travel planning, restaurant discovery, or review analysis workflows.
metadata: {"openclaw": {"emoji": "🦉", "requires": {"env": ["SERPAPI_KEY"]}, "primaryEnv": "SERPAPI_KEY"}}
---

# SerpApi TripAdvisor

Search TripAdvisor and get detailed place data through SerpApi's structured JSON API. Two engines cover all TripAdvisor data needs.

## Setup

Requires `SERPAPI_KEY` environment variable. All requests are GET to `https://serpapi.com/search` with `api_key` parameter.

## Engines Overview

| Engine | Purpose | Key Parameter |
|--------|---------|---------------|
| `tripadvisor` | Search TripAdvisor | `q` (query) |
| `tripadvisor_place` | Place details (restaurant, hotel, attraction, destination) | `place_id` |

---

## 1. TripAdvisor Search

### Basic Search

```bash
curl -s "https://serpapi.com/search?engine=tripadvisor&q=Rome&api_key=$SERPAPI_KEY"
```

### Filtered Search (Restaurants Only)

```bash
curl -s "https://serpapi.com/search?engine=tripadvisor&q=sushi+Tokyo&ssrc=r&api_key=$SERPAPI_KEY"
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | Yes | Search query (anything you'd type into TripAdvisor) |
| `ssrc` | No | Category filter: `a` = All (default), `r` = Restaurants, `A` = Things to Do, `h` = Hotels, `g` = Destinations, `f` = Forums |
| `lat` | No | GPS latitude for location-based search |
| `lon` | No | GPS longitude for location-based search |
| `tripadvisor_domain` | No | Domain for localization (default: `tripadvisor.com`). Examples: `tripadvisor.co.uk`, `tripadvisor.fr`, `tripadvisor.de` |
| `offset` | No | Result offset for pagination (`0` = page 1, `30` = page 2, `60` = page 3) |
| `limit` | No | Max results to return (default: `30`, max: `100`) |

### Response: `places[]`

Each place in the results array:

| Field | Description |
|-------|-------------|
| `position` | Rank in results |
| `title` | Place name |
| `place_id` | TripAdvisor place ID (use with `tripadvisor_place` engine) |
| `place_type` | `GEO`, `ACCOMMODATION`, `RESTAURANT`, `ATTRACTION_PRODUCT`, `EATERY`, etc. |
| `link` | TripAdvisor URL |
| `description` | Short description or snippet |
| `rating` | Rating (1-5 scale) |
| `reviews` | Review count |
| `location` | Location string (e.g., "Rome, Lazio, Italy") |
| `thumbnail` | Image URL |
| `highlighted_review` | Object with `text`, `highlighted_texts[]`, `mention_count` |

### Pagination

Use `serpapi_pagination.next` for the next page URL, or manually increment `offset` by 30.

---

## 2. Place Details

Get full details for any place found via search. The response structure varies by place type.

### Basic Request

```bash
curl -s "https://serpapi.com/search?engine=tripadvisor_place&place_id=187791&api_key=$SERPAPI_KEY"
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `place_id` | Yes | TripAdvisor place ID (from search results) |
| `tripadvisor_domain` | No | Domain for localization (default: `tripadvisor.com`) |

### Response: `place_result`

The `type` field determines what data is available. Four types:

---

### Destination (`type: "destination"`)

Returned for cities, regions, countries (`place_type: GEO`).

| Field | Description |
|-------|-------------|
| `name` | Destination name (e.g., "Paris, France") |
| `images[]` | Photo URLs |
| `travel_advice[]` | Articles: `{ title, link }` (best areas, best time, itineraries) |
| `attraction_suggestions.items[]` | Top attractions: `{ name, place_id, rating, reviews, address, categories[] }` |
| `hotel_suggestions.items[]` | Top hotels: `{ name, place_id, rating, reviews, price, address }` |
| `restaurant_suggestions.items[]` | Top restaurants: `{ name, place_id, rating, reviews, address, cuisines[], diets[] }` |

Each suggestion includes `serpapi_link` for direct place lookup.

---

### Restaurant (`type: "restaurant"`)

| Field | Description |
|-------|-------------|
| `name`, `rating`, `reviews` | Basic info |
| `is_claimed` | Owner-claimed listing |
| `ranking` | e.g., "#863 of 20,004 Restaurants in Paris" |
| `categories[]` | Price range, cuisine type: `{ name, link }` |
| `cuisines[]` | Cuisine list (e.g., "French", "Bar", "European") |
| `diets[]` | Dietary options (e.g., "Vegetarian friendly", "Gluten free options") |
| `meal_types[]` | "Breakfast", "Lunch", "Dinner", etc. |
| `dining_options[]` | "Takeout", "Reservations", "Outdoor Seating", etc. |
| `menu` | Full menu with `categories[].sections[].items[]` (name, description, price) and `popular_dishes[]` |
| `operation_hours` | `{ currently_open, hours[]: { day, hours } }` |
| `address`, `phone`, `email`, `website` | Contact info |
| `neighborhood`, `neighborhood_description` | Area context |
| `reviews_summary` | AI-generated review summary |
| `reviews_highlights[]` | Categorized highlights: `{ category, value, summary, reviews_quotes[] }` (Wait time, Service, Food, etc.) |
| `reviews_list[]` | Individual reviews: `{ title, snippet, rating, date, author }` |
| `images[]` | Photo URLs |

---

### Hotel (`type: "hotel"`)

| Field | Description |
|-------|-------------|
| `name`, `rating`, `reviews` | Basic info |
| `ranking` | e.g., "#454 of 1,873 hotels in Paris" |
| `prices` | Live pricing: `{ check_in, check_out, rooms, guests, offers[] }` |
| `prices.offers[]` | Booking options: `{ price, extracted_price, provider, original_price, lowest_price, rooms_remaining, link }` |
| `price_trends[]` | Date-price pairs: `{ date, price }` |
| `subratings[]` | Category scores: `{ category, score }` (Location, Rooms, Value, etc.) |
| `description` | Hotel description |
| `operation_hours` | Check-in/out info |
| `address`, `phone`, `website` | Contact info |
| `neighborhood`, `neighborhood_description` | Area context |
| `reviews_summary`, `reviews_highlights[]`, `reviews_list[]` | Same structure as restaurants |
| `images[]` | Photo URLs |

---

### Attraction (`type: "attraction"`)

| Field | Description |
|-------|-------------|
| `name`, `rating`, `reviews` | Basic info |
| `ranking` | e.g., "#15 of 4,211 things to do in Paris" |
| `description` | Detailed description |
| `duration` | Suggested visit time (e.g., "2-3 hours") |
| `price`, `extracted_price` | Entry price |
| `highlights[]` | Notable features: `{ title, snippet, image }` |
| `attraction_listings[]` | Tours and tickets grouped by category |
| `attraction_listings[].list[]` | Each listing: `{ name, place_id, rating, reviews, type, duration, free_cancellation, labels[], price, extracted_price }` |
| `operation_hours` | Opening hours |
| `getting_here[]` | Transit directions (e.g., "Palais Royal – Musée du Louvre • 3 min walk") |
| `address`, `phone`, `email`, `website` | Contact info |
| `neighborhood`, `neighborhood_description` | Area context |
| `reviews_summary`, `reviews_highlights[]`, `reviews_list[]` | Same structure as restaurants |
| `images[]` | Photo URLs |

---

## Common Workflows

### Find Best Restaurants in a City

1. Search: `engine=tripadvisor&q=restaurants+Barcelona&ssrc=r`
2. Get details: `engine=tripadvisor_place&place_id=PLACE_ID` for top results
3. Check `reviews_summary`, `cuisines`, `menu`, `operation_hours`

### Compare Hotels with Pricing

1. Search: `engine=tripadvisor&q=hotels+Rome+near+Colosseum&ssrc=h`
2. Get details for each: `engine=tripadvisor_place&place_id=PLACE_ID`
3. Compare `prices.offers[]` for live pricing across providers
4. Check `price_trends[]` for pricing patterns
5. Compare `subratings[]` for detailed category scores

### Plan a Trip to a Destination

1. Get destination overview: `engine=tripadvisor_place&place_id=CITY_ID`
2. Browse `attraction_suggestions`, `hotel_suggestions`, `restaurant_suggestions`
3. Drill into individual places using their `place_id`
4. Check `travel_advice[]` for local tips and itineraries

### Find Tours and Tickets for an Attraction

1. Get attraction details: `engine=tripadvisor_place&place_id=ATTRACTION_ID`
2. Browse `attraction_listings[]` grouped by category
3. Each listing has `price`, `duration`, `free_cancellation`, `rating`

### Location-Based Restaurant Search

1. Search with coordinates: `engine=tripadvisor&q=pizza&lat=40.7128&lon=-74.0060&ssrc=r`
2. Results prioritize places near the given location

## Localization

Use `tripadvisor_domain` to get results in different languages and regional contexts:

| Domain | Country |
|--------|---------|
| `tripadvisor.com` | United States (default) |
| `tripadvisor.co.uk` | United Kingdom |
| `tripadvisor.fr` | France |
| `tripadvisor.de` | Germany |
| `tripadvisor.es` | Spain |
| `tripadvisor.it` | Italy |
| `tripadvisor.ca` | Canada (English) |
| `tripadvisor.com.br` | Brazil |
| `tripadvisor.com.mx` | Mexico |
| `tripadvisor.co` | Colombia |
| `tripadvisor.com.tr` | Turkey |
| `tripadvisor.nl` | Netherlands |
| `tripadvisor.se` | Sweden |

This is a partial list. Use `www.` prefix for all domains. Full list at SerpApi's TripAdvisor domains page.

## Common Destination Place IDs

Quick-start reference for major destinations. Use these with `tripadvisor_place` to browse suggestions directly without searching.

| Destination | `place_id` |
|-------------|------------|
| New York City | `60763` |
| Paris | `187147` |
| Rome | `187791` |
| Tokyo | `298184` |
| London | `186338` |
| Barcelona | `187497` |
| Bangkok | `293916` |
| Dubai | `295424` |
| Istanbul | `293974` |
| Sydney | `255060` |

These IDs return `type: "destination"` responses with `attraction_suggestions`, `hotel_suggestions`, and `restaurant_suggestions` — useful for trip planning or as a fallback when search is unavailable.

---

## Troubleshooting

### Search Engine Returns Empty Results

The `tripadvisor` search engine may occasionally return empty results (`"Tripadvisor hasn't returned any results for this query."`) for all queries. This is a known SerpApi backend issue, not a query problem.

**How to confirm it's a backend issue (not your query):**
- Try a simple, broad query like `q=Rome` with no filters
- Try adding `no_cache=true` to force a fresh result
- If ALL queries return empty (including simple ones), it's a SerpApi-side outage

**Fallback pattern when search is unavailable:**

1. **Use `tripadvisor_place` with known destination IDs** — see the [Common Destination Place IDs](#common-destination-place-ids) table above. A destination lookup returns `attraction_suggestions`, `hotel_suggestions`, and `restaurant_suggestions` you can drill into.
2. **Extract place IDs from TripAdvisor URLs** — if you have a TripAdvisor URL like `https://www.tripadvisor.com/Restaurant_Review-g187147-d1234567-...`, the `d` number (`1234567`) is the `place_id`. Use it with `tripadvisor_place`.
3. **Use other search tools to find TripAdvisor URLs** — search the web for "site:tripadvisor.com [query]", extract place IDs from the URLs, then use `tripadvisor_place` for structured data.

The `tripadvisor_place` engine is independently reliable and works even when the search engine is down.

---

## Error Handling

- Check `search_metadata.status` — should be `"Success"`
- Invalid `place_id` returns an error — verify IDs come from search results or known destination IDs
- `no_cache=true` forces fresh results (costs 1 credit). Don't combine with `async`
- Vacation Rental place IDs may return incomplete or empty data (TripAdvisor discontinued support)
- Hotel pricing in `place_result` reflects live availability — results vary by date
- Empty search results across all queries likely indicate a SerpApi backend outage — see [Troubleshooting](#troubleshooting)

## Detailed Reference

For complete response schemas, all field descriptions, and extended JSON examples: see [references/api-reference.md](references/api-reference.md).
