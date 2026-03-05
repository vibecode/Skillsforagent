---
name: serp-tripadvisor
description: >
  Specialized skill for Tripadvisor travel workflows via SerpApi — restaurant discovery,
  hotel comparison with live pricing, attraction and tour planning, destination exploration,
  review analysis, and trip itinerary building. Use when: (1) finding the best restaurants
  in a city with reviews and menus, (2) comparing hotels with live pricing across booking
  providers, (3) exploring things to do and tours at a destination, (4) planning a trip
  itinerary with restaurants, hotels, and attractions, (5) analyzing Tripadvisor reviews
  for a place, (6) finding places near a GPS location, (7) getting detailed info about
  a specific restaurant, hotel, or attraction on Tripadvisor, (8) checking hotel price
  trends over time, (9) curating a mood board of dining or travel options, (10) any
  Tripadvisor-based travel research or planning task. This skill builds on the foundational
  serpapi skill for all API details.
metadata: {"openclaw": {"emoji": "🦉", "requires": {"env": ["SERPAPI_KEY"]}, "primaryEnv": "SERPAPI_KEY"}}
---

# Tripadvisor Travel Workflows

Restaurant discovery, hotel comparison, attraction planning, destination exploration, and review analysis via SerpApi's Tripadvisor engines. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engines: `tripadvisor`, `tripadvisor_place`)

## Engine Selection

| Engine | Purpose | Key Input |
|--------|---------|-----------|
| `tripadvisor` | Search Tripadvisor for places | `q` (query string) |
| `tripadvisor_place` | Get full details for a specific place | `place_id` |

## Category Filters

When searching, use `ssrc` to narrow by category:

| Filter | Value | Best For |
|--------|-------|----------|
| All | `a` (default) | Broad exploration |
| Restaurants | `r` | Dining discovery |
| Hotels | `h` | Accommodation search |
| Things to Do | `A` | Attractions, tours, activities |
| Destinations | `g` | City/region overviews |
| Forums | `f` | Traveler discussions |

## Place Types in Responses

The `tripadvisor_place` engine returns different data depending on the place type:

| Type | What You Get |
|------|-------------|
| `destination` | City overview with top attraction, hotel, and restaurant suggestions + travel advice |
| `restaurant` | Menu, cuisines, dietary options, meal types, dining options, hours, reviews |
| `hotel` | Live pricing from multiple providers, price trends, subratings (location, rooms, value), reviews |
| `attraction` | Duration, highlights, tour/ticket listings with prices, getting-there directions, reviews |

All types include: name, rating, review count, address, phone, website, images, reviews_summary, reviews_highlights, reviews_list.

## Workflows

### 1. Restaurant Discovery

Find the best restaurants in a location.

**Search:** Use `tripadvisor` engine with `ssrc=r` and a location-based query (e.g., "sushi Tokyo", "restaurants Barcelona").

**Refine with coordinates:** Add `lat` and `lon` for "near me" style searches.

**Drill down:** Use `tripadvisor_place` with the `place_id` from results to get:
- Full menu with categories, items, descriptions, and prices
- Popular dishes
- Cuisines and dietary options (vegetarian, gluten-free, etc.)
- Dining options (takeout, reservations, outdoor seating)
- Operating hours and current open/closed status
- Review highlights organized by category (Food, Service, Wait time, etc.)

**Present results as:**
```
🍽️ Top Restaurants: [Location]

1. [Name] ⭐ [rating] ([reviews] reviews)
   📍 [location] | 🏷️ [cuisines]
   💬 "[review summary or highlighted review snippet]"

2. ...
```

For detailed restaurant profiles, include menu highlights, hours, and review themes.

### 2. Hotel Comparison

Compare hotels with live pricing from booking providers.

**Search:** Use `tripadvisor` engine with `ssrc=h`.

**Get pricing:** Use `tripadvisor_place` for each hotel to access:
- `prices.offers[]` — Live rates from Booking.com, Expedia, Hotels.com, etc.
- Each offer includes: provider, price, original price (if discounted), rooms remaining
- `price_trends[]` — Date-price pairs showing how rates change over time
- `subratings[]` — Detailed scores for Location, Rooms, Service, Value, Cleanliness, Sleep Quality

**Comparison pattern:**
1. Search for hotels in the target area
2. Get details for the top 3-5 results
3. Compare by: best price across providers, subratings, location, review highlights
4. Present a comparison table (or bullet list for Discord/WhatsApp)

**Present results as:**
```
🏨 Hotel Comparison: [Location]

1. [Name] ⭐ [rating] ([reviews] reviews)
   📍 [neighborhood]
   💰 From $[lowest price] ([provider])
   📊 Location: [score] | Rooms: [score] | Value: [score]
   
2. ...

💡 Price tip: [price trend observation]
```

### 3. Attraction & Tour Planning

Find things to do and book tours/tickets.

**Search:** Use `tripadvisor` engine with `ssrc=A`.

**Get details:** Use `tripadvisor_place` for attractions to access:
- `duration` — Suggested visit time
- `highlights[]` — Notable features with descriptions
- `attraction_listings[]` — Tours and tickets grouped by category
  - Each listing: name, price, duration, rating, free cancellation flag
- `getting_here[]` — Transit directions to the attraction

**Workflow for "plan a day":**
1. Search for things to do in the area
2. Get details for top-rated attractions
3. Check durations to estimate how many fit in a day
4. Note tour/ticket options with prices and cancellation policies
5. Check operating hours for scheduling

**Present results as:**
```
🎯 Things to Do: [Location]

1. [Name] ⭐ [rating] ([reviews] reviews)
   ⏱️ [duration] | 💰 [price range]
   📝 [description snippet]
   🎟️ [number] tours available from $[lowest]
   
2. ...
```

### 4. Destination Overview

Get a comprehensive overview of a city or region.

**Direct lookup:** Use `tripadvisor_place` with a known destination `place_id` (see Quick-Start IDs below).

**Search first:** Use `tripadvisor` engine with `ssrc=g` if you don't have the place_id.

**What you get:**
- `travel_advice[]` — Curated articles (best areas to stay, best time to visit, itineraries)
- `attraction_suggestions` — Top-rated things to do
- `hotel_suggestions` — Top-rated places to stay (with prices)
- `restaurant_suggestions` — Top-rated dining options

**Use for trip planning:** The destination response gives you a starting point for all three categories. Drill into each suggestion's `place_id` for full details.

### 5. Review Analysis

Deep-dive into reviews for a specific place.

**Get reviews:** Use `tripadvisor_place` — the response includes:
- `reviews_summary` — AI-generated summary of all reviews
- `reviews_highlights[]` — Categorized highlights with:
  - `category` — e.g., "Food", "Service", "Location", "Rooms"
  - `summary` — Brief category assessment
  - `reviews_quotes[]` — Supporting quotes from actual reviews
- `reviews_list[]` — Individual reviews with title, snippet, rating, date, author

**Analysis patterns:**
- **Sentiment overview:** Lead with `reviews_summary`, then highlight themes from `reviews_highlights`
- **Red flags:** Look for low-scoring categories in highlights
- **Recent trends:** Check dates in `reviews_list` — are recent reviews better or worse than overall rating?
- **Specific concerns:** Search highlights for categories the user cares about (e.g., "Service" for a restaurant, "Rooms" for a hotel)

### 6. Location-Based Search

Find places near specific GPS coordinates.

**How:** Add `lat` and `lon` parameters to any `tripadvisor` search. Combine with `ssrc` to filter by category.

**Use cases:**
- "Restaurants near my hotel" — search with hotel coordinates + `ssrc=r`
- "Things to do near [landmark]" — search with landmark coordinates + `ssrc=A`
- "Closest coffee shops" — search with current coordinates + relevant query

### 7. Trip Itinerary Building

Combine multiple workflows to build a complete trip plan.

**Step 1 — Destination overview:** Get the destination page for the target city. Review travel advice and top suggestions.

**Step 2 — Accommodation:** Search hotels, compare prices and subratings. Pick based on budget, location, and priorities.

**Step 3 — Dining:** Search restaurants near the chosen hotel (use coordinates). Identify options for different meals and cuisines.

**Step 4 — Activities:** Search things to do. Get details for top attractions — check durations and hours to plan daily schedules.

**Step 5 — Compile:** Organize by day with time blocks, including transit considerations from `getting_here` data.

## Quick-Start Destination IDs

Use these with `tripadvisor_place` to jump straight into destination details without searching:

| Destination | place_id |
|-------------|----------|
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

These return `destination` type responses with suggestions for attractions, hotels, and restaurants — useful as starting points or when search is unavailable.

## Localization

Use `tripadvisor_domain` to get results in local languages and regional contexts. Examples: `tripadvisor.co.uk` (UK), `tripadvisor.fr` (France), `tripadvisor.de` (Germany), `tripadvisor.es` (Spain), `tripadvisor.it` (Italy).

Set the domain matching the user's language or the destination's region for the most relevant results.

## Troubleshooting

### Search Returns Empty Results

The `tripadvisor` search engine may occasionally return empty results for all queries due to SerpApi backend issues.

**Confirm it's a backend issue:** Try a simple broad query like just "Rome" — if that returns empty too, it's not your query.

**Fallback pattern:**
1. Use `tripadvisor_place` with known destination IDs (see table above) — place lookups work independently of search
2. Extract place IDs from Tripadvisor URLs — the `d` number in a URL like `/Restaurant_Review-g187147-d1234567-...` is the `place_id`
3. Use web search for "site:tripadvisor.com [query]", then extract place IDs from the URLs

### Pagination

Search results come in pages of ~30. Use `offset` parameter: 0 (page 1), 30 (page 2), 60 (page 3). Or use the `serpapi_pagination.next` URL from the response.

## Tips

- **Start broad, then drill down.** Search → pick interesting results → get full details with `tripadvisor_place`.
- **Destination pages are goldmines.** One API call gives you curated top suggestions across all categories.
- **Hotel pricing varies by date.** The `prices` data reflects live availability — mention check-in/check-out dates when presenting prices.
- **Review highlights > full reviews.** The `reviews_highlights` array gives you categorized, summarized insights without reading dozens of individual reviews.
- **Combine with other skills.** Use Google Maps (serp-google-maps) for walking distances, Google Flights (serp-google-flights) for travel costs, and Google Images (serp-google-images) for visual previews.
