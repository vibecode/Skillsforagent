---
name: serp-google-maps
display_name: Google Maps
description: >
  Specialized skill for Google Maps local search workflows via SerpApi — find businesses,
  restaurants, services, and places with ratings, reviews, hours, and contact details.
  Use when: (1) searching for local businesses or services near a location, (2) finding
  restaurants, cafes, or shops in a specific area, (3) getting detailed place information
  (address, phone, hours, reviews, photos), (4) analyzing business reviews from Google Maps,
  (5) comparing local businesses by rating, reviews, or proximity, (6) resolving a specific
  business or place by name, (7) exploring what's nearby a given location or GPS coordinates,
  (8) checking business hours or contact details, (9) any local search or place discovery
  task involving Google Maps. This skill builds on the foundational serpapi skill for all
  API details.
dependencies:
  - serpapi
metadata: {"openclaw": {"emoji": "📍"}}
---

# Google Maps Local Search Workflows

Local business search, place details, reviews, photos, and nearby discovery via the SerpApi Google Maps engines. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engines: `google_maps`, `google_maps_reviews`, `google_maps_photos`, `google_maps_posts`)

## Core Concepts

### Engines Overview

| Engine | Purpose | Key Parameter |
|--------|---------|---------------|
| `google_maps` | Local search + place details | `q` (search), `place_id` or `data_cid` (place) |
| `google_maps_reviews` | Business reviews | `data_id` (from local results) |
| `google_maps_photos` | Place photos | `data_id` |
| `google_maps_posts` | Business posts/updates | `data_id` |

### Location Targeting

All searches benefit from location context. Three approaches:

| Method | Parameter | Example | Best For |
|--------|-----------|---------|----------|
| GPS coordinates | `ll` | `@40.7455,-74.0083,14z` | Precise radius search |
| Named location | `location` | `New York, NY` | General area search |
| Query-embedded | (in `q`) | `"pizza in Brooklyn"` | Quick, no separate param |

**GPS format:** `@latitude,longitude,zoom` — zoom is `Xz` (e.g., `14z`) or `Xm` (meters, e.g., `10000m`). Lower zoom = wider area. Typical: `12z` (city), `14z` (neighborhood), `16z` (block).

### Key IDs

Results return several IDs used for follow-up queries:

| ID | Source | Used For |
|----|--------|----------|
| `place_id` | `local_results[].place_id` | Direct place lookup via `google_maps` |
| `data_id` | `local_results[].data_id` | Reviews, photos, and posts engines |
| `data_cid` | `local_results[].data_cid` | Direct place lookup via `google_maps` |

**Important:** `data_id` is required for reviews, photos, and posts. `place_id` or `data_cid` is used for place details.

### Response Structure — Local Search

A `google_maps` search with `type=search` returns `local_results[]`. Each result includes:
- `title` — Business name
- `rating` / `reviews` — Star rating (float) and review count
- `type` / `types` — Business category (e.g., "Coffee shop", ["Coffee shop", "Cafe"])
- `address` — Street address
- `phone` — Phone number
- `website` — Business website URL
- `hours` / `operating_hours` — Current status and full schedule
- `gps_coordinates` — `{ latitude, longitude }`
- `price` — Price level (e.g., "$", "$$", "$$$")
- `description` — Short description or highlight
- `service_options` — Delivery, takeout, dine-in flags
- `thumbnail` — Image URL
- `place_id`, `data_id`, `data_cid` — IDs for follow-up queries
- `open_state` — Current open/closed status

### Response Structure — Place Details

A place lookup (via `place_id` or `data_cid`) returns `place_results` with extended info:
- Everything from local results, plus:
- `user_reviews` — `{ summary, most_relevant[], topics[] }` — quick review snapshot
- `extensions` — Categorized attributes (highlights, accessibility, crowd, planning, payments, etc.)
- `images[]` — Photos with titles and thumbnails
- `people_also_search_for[]` — Related businesses
- `similar_places_nearby[]` — Competitor businesses
- `booking_link` — Direct booking URL (if applicable)
- `directions` — Link to Google Maps directions
- `events[]` — Upcoming events at the place (if any)

## Workflows

### 1. Basic Local Search

Use the **serpapi** skill's wrapper script with the `google_maps` engine.

**Required:** `q` (search query)
**Recommended:** `ll` or `location` for geographic targeting, `type` set to `search`

**Useful parameters:**
- `type` — `search` for list results (default behavior when `q` is set)
- `ll` — GPS coordinates with zoom: `@lat,lon,Xz`
- `start` — Pagination offset (0, 20, 40, etc.) — requires `ll` to be set
- `gl` / `hl` — Country and language localization

**What to present:** Top 5-8 results with name, rating, review count, type, price level, address, and open status.

### 2. Place Details Deep Dive

When a user wants full details about a specific business:

**Option A — By place_id:**
Pass `place_id` from search results to the `google_maps` engine. No `type` or `q` needed.

**Option B — By data_cid:**
Pass `data_cid` from search results. Same behavior as place_id.

**Option C — By data parameter:**
For places found via `data_id`, use `type=place` and pass the data value.

**What you get:**
- Full contact info (address, phone, website, directions)
- Operating hours (full weekly schedule)
- User review summary with topic breakdown
- Extensions (accessibility, payments, amenities, crowd info)
- Photos and thumbnail images
- Related and similar places
- Booking links (restaurants, services)

**Presentation pattern:**
1. Business name, type, rating, and review count
2. Address and phone
3. Hours (today's hours prominently, full schedule if asked)
4. Key highlights from extensions
5. Review summary and top topics
6. Similar places for comparison

### 3. Review Analysis

For deep review analysis, use `google_maps_reviews` with `data_id`:

**Sort options:**
- `qualityScore` — Most relevant (default)
- `newestFirst` — Most recent
- `ratingHigh` — Highest rated first
- `ratingLow` — Lowest rated first

**Filtering:**
- `topic_id` — Filter by topic (available from place details `user_reviews.topics[]`)
- `next_page_token` — Paginate through reviews

**Each review includes:**
- `user` — Reviewer name, link, thumbnail, number of reviews/photos
- `rating` — 1-5 star rating
- `date` — When posted
- `snippet` — Review text
- `likes` — Helpful votes
- `response` — Owner's reply (if any)
- `images[]` — Reviewer's photos

**Presentation pattern:**
- Overall rating and total reviews
- Top topics from place details
- 3-5 representative reviews (mix of positive and negative)
- Owner response highlights (shows engagement)
- Recent trend — are newer reviews better or worse?

### 4. Nearby Discovery

When a user wants to explore what's around a specific location:

**Strategy:**
1. Get GPS coordinates (from a known place, address, or user-provided lat/lon)
2. Search with `ll` parameter centered on those coordinates
3. Adjust zoom for desired radius: `14z` (neighborhood), `12z` (city area), `16z` (immediate vicinity)

**Example queries:**
- "restaurants near Times Square" → `q=restaurants`, `ll=@40.758,-73.9855,15z`
- "what's around my hotel" → Get hotel's GPS from place details, then search categories
- "coffee shops within walking distance" → Tight zoom: `16z` or `17z`

### 5. Business Comparison

When a user wants to compare multiple businesses:

**Step 1:** Search to find candidates matching the category.

**Step 2:** Get place details for the top 3-5 candidates to compare extended info.

**Step 3:** Present comparison:

```
📍 Business Comparison: [Category] in [Area]

| | ⭐ Rating | 📝 Reviews | 💰 Price | ⏰ Hours Today | 📍 Distance |
|---|-----------|-----------|---------|---------------|-------------|
| [Business A] | 4.7 | 2,341 | $$ | 8am-10pm | 0.3 mi |
| [Business B] | 4.5 | 892 | $$$ | 9am-11pm | 0.5 mi |
| [Business C] | 4.8 | 456 | $$ | 7am-9pm | 0.8 mi |

Key differences:
• [A] — Best for: [highlights from extensions]
• [B] — Best for: [highlights from extensions]
• [C] — Best for: [highlights from extensions]
```

### 6. Service-Specific Searches

Different business types benefit from different query strategies:

| Need | Query Pattern | Key Fields to Show |
|------|---------------|-------------------|
| Restaurant | `"italian restaurant"` + location | rating, price, hours, service_options (dine-in/delivery) |
| Hotel | `"hotels"` + location | rating, price, booking_link |
| Doctor/Dentist | `"dentist"` + location | rating, reviews, hours, phone |
| Auto repair | `"auto mechanic"` + location | rating, reviews, hours, phone |
| Gas station | `"gas station"` + location | price, hours, open_state |
| Store | `"hardware store"` + location | hours, phone, open_state |

**Service options matter for restaurants:** Check `service_options` for dine_in, takeout, delivery, no_contact_delivery flags.

### 7. Photos and Posts

For visual context or business updates:

**Photos** (`google_maps_photos` engine):
- Pass `data_id` from search results
- Returns categorized photo URLs (by Google, by owner, by customers)
- Useful for: venue previews, menu photos, ambiance checks

**Posts** (`google_maps_posts` engine):
- Pass `data_id` from search results
- Returns business updates, offers, events
- Useful for: current promotions, recent news, event announcements

### 8. Iterative Refinement

When initial results don't match what the user needs:

**Narrow by type:** Make the query more specific ("vegan restaurant" vs "restaurant").

**Narrow by area:** Tighten zoom in `ll` parameter (14z → 16z) or add neighborhood to query.

**Expand results:** Paginate with `start` parameter (20, 40, 60). **Note:** Pagination requires `ll` to be set. Filters (price, rating) don't work with pagination.

**Switch approach:** If search returns too many irrelevant results, try a more descriptive query or add location qualifiers directly in `q`.

## Presenting Results

### Local Search Summary

For each business:

```
📍 [Business Name] — [Type]
   ⭐ [Rating] ([Review Count] reviews) | 💰 [Price Level]
   📌 [Address]
   ⏰ [Open/Closed status] | [Today's hours]
   📞 [Phone] | 🌐 [Website]
   [🚗 Delivery] [🥡 Takeout] [🍽️ Dine-in]
```

### Place Detail Summary

```
📍 [Business Name] — [Type]
   ⭐ [Rating] ([Reviews] reviews) | 💰 [Price]
   📌 [Full Address]
   📞 [Phone] | 🌐 [Website]
   
   ⏰ Hours:
   Mon-Fri: [hours]  |  Sat: [hours]  |  Sun: [hours]
   
   ✨ Highlights: [from extensions — e.g., "Outdoor seating, Free Wi-Fi, Wheelchair accessible"]
   
   📊 Review Topics:
   • [Topic 1] — mentioned [X] times
   • [Topic 2] — mentioned [X] times
   
   📝 Top Review: "[snippet]" — [user], [rating]★
   
   👀 Similar: [Business X], [Business Y], [Business Z]
```

## Common Patterns

### "Find a good [type] near [location]"
1. Search with `q` and `ll` or `location`
2. Present top results sorted by relevance (Google's default ranking balances rating, reviews, proximity)
3. Offer to filter by rating, price, or compare top picks

### "Is [Business] open right now?"
1. Look up place by name (search or place_id)
2. Check `open_state` and `operating_hours` in results
3. Report current status and today's full hours

### "Reviews for [Business]"
1. Search to find the business and get `data_id`
2. Get place details for review summary and topics
3. Fetch full reviews via `google_maps_reviews` for detailed analysis
4. Present overall sentiment + specific review highlights

### "Compare [Business A] vs [Business B]"
1. Search for each to find their IDs
2. Get place details for both
3. Side-by-side comparison: rating, reviews, price, hours, highlights, review topics

### "Best [type] in [city]"
1. Search with descriptive query
2. Results come pre-ranked by Google's quality algorithm
3. Present top 5-8 with ratings and key differentiators
4. Offer deeper dives on any that interest the user

### "What's around [address/place]?"
1. Get GPS coordinates (look up the place if needed)
2. Run category searches: restaurants, cafes, shops, attractions
3. Group results by type and distance

## Tips

- **Pagination requires `ll`:** When paginating with `start`, the `ll` parameter must be set. Without it, pagination won't work.
- **Filters don't paginate:** Price, rating, and other filters work on the first page only. They're ignored with `start` offsets.
- **`data_id` is the universal key:** Reviews, photos, and posts all need `data_id`, not `place_id`. Always capture it from search results.
- **Zoom controls radius:** `ll` zoom level directly affects how wide the search area is. `14z` ≈ neighborhood, `12z` ≈ city region, `17z` ≈ single block.
- **Place lookups don't need `q`:** When using `place_id` or `data_cid`, you don't need a query string — just the ID.
- **Localization:** Use `gl` and `hl` for region/language-appropriate results, names, and review language.
- **service_options:** For restaurants, always check and present delivery/takeout/dine-in availability — it's often what users care about.
- **Owner responses in reviews:** Businesses that reply to reviews tend to be more engaged. Mention this when presenting review analysis.
- **`people_also_search_for` and `similar_places_nearby`** from place details are excellent for expanding recommendations.
