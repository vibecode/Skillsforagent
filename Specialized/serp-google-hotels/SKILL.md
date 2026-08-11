---
name: serp-google-hotels
display_name: Google Hotels
description: >
  Specialized skill for Google Hotels workflows via SerpApi — hotel search, vacation rental
  search, property detail lookup, photo galleries, and review analysis. Use when: (1) searching
  for hotels in a city or area for specific check-in/check-out dates, (2) finding vacation
  rentals with bedroom/bathroom requirements, (3) filtering by price, hotel class, amenities,
  rating, or free cancellation, (4) sorting properties by lowest price, highest rating, or
  most reviewed, (5) fetching deep property details (full rates, all amenities, room info)
  via property_token, (6) browsing a hotel's photo gallery by section, (7) reading hotel
  reviews with subratings and source breakdown, (8) comparing multiple properties side by
  side, (9) resolving city or landmark names to property tokens via autocomplete, (10) any
  travel planning task involving hotel or short-term rental booking. This skill builds on
  the foundational serpapi skill for all API details.
dependencies:
  - serpapi
metadata: {"openclaw": {"emoji": "🏨"}}
---

# Google Hotels Workflows

Hotel and vacation rental search, property deep-dives, photo galleries, and review analysis via SerpApi's Google Hotels engines. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engines: `google_hotels`, `google_hotels_photos`, `google_hotels_reviews`, `google_hotels_autocomplete`)

## Core Concepts

### The Two-Step Property Pattern

Google Hotels uses a search-then-detail pattern very similar to flights:

1. **Search** with `google_hotels` (query + dates) → returns a `properties[]` array. Each property has a `property_token`.
2. **Deep dive** by passing that `property_token` back to `google_hotels` → returns full rates from all sources, complete amenities, room types, detailed reviews breakdown, nearby places.

The same `property_token` is the key to two other engines:
- `google_hotels_photos` — photo gallery for the property
- `google_hotels_reviews` — full paginated reviews

Always capture `property_token` from search results before drilling in.

### Hotels vs Vacation Rentals

The `properties[]` array can contain two `type` values: `"hotel"` or `"vacation rental"`. By default search returns hotels. To search vacation rentals, set `vacation_rentals=true`.

Vacation rentals have different filters and fields:
- Use `bedrooms` and `bathrooms` as minimum-count filters
- `essential_info` carries bedroom/bathroom counts (instead of `hotel_class`)
- No `hotel_class` filter applies

### Response Structure

A search returns:

- **`properties[]`** — Main results. Each property has:
  - `type` — `"hotel"` or `"vacation rental"`
  - `name`, `description`, `link`, `address`, `phone`, `gps_coordinates`
  - `property_token` — Use for detail / photos / reviews engines
  - `check_in_time`, `check_out_time`
  - `rate_per_night`, `total_rate` — Each with `lowest`, `extracted_lowest`, `before_taxes_fees`
  - `prices[]` — Different sources offering rates
  - `images[]` — Thumbnail + original URLs
  - `overall_rating`, `reviews` (count), `location_rating`
  - `amenities[]`, `excluded_amenities[]`
  - `hotel_class` — Star rating (hotels only)
  - `essential_info` — Bedrooms/bathrooms (vacation rentals)
  - `ratings[]` — Distribution by star count
  - `reviews_breakdown[]` — Per-category review themes (Service, Property, Nature, etc.)
  - `sponsored` — Boolean flag
- **`ads[]`** — Sponsored listings (separate from organic properties)
- **`brands[]`** — Brand IDs with nested `children` for use in the `brands` filter
- **`search_information`** — `total_results`, `hotels_results_state`
- **`serpapi_pagination`** — `current_from`, `current_to`, `next_page_token`

A `property_token` deep-dive response adds: full per-source `prices[]`, room types, complete amenities, location highlights, nearby attractions, and a structured `reviews_breakdown` with themed snippets.

### Pagination

Hotel searches paginate via `next_page_token`. Pass the token from `serpapi_pagination.next_page_token` back as the `next_page_token` parameter on the next call to get the next page.

## Workflows

### 1. Basic Hotel Search

Use the **serpapi** skill's wrapper script with the `google_hotels` engine.

**Required parameters:**
- `q` — Query string (city, neighborhood, landmark, or hotel name)
- `check_in_date` — `YYYY-MM-DD`
- `check_out_date` — `YYYY-MM-DD`

**Traveler config:**
- `adults` (default `2`), `children` (default `0`)
- `children_ages` — Comma-separated ages 1-17 (e.g., `5,8,10`). Required if `children > 0`.

**Localization:**
- `currency` (default `USD`), `gl` (country), `hl` (language)

**What to present:** Top 5-10 properties from `properties[]` with name, hotel class (if hotel), nightly rate, overall rating + review count, key amenities, and address. Note if `sponsored: true`.

### 2. Vacation Rental Search

Set `vacation_rentals=true` to switch from hotels to short-term rentals.

**Rental-specific filters:**
- `bedrooms` — Minimum bedroom count (default `0`)
- `bathrooms` — Minimum bathroom count (default `0`)

**Things that don't apply to rentals:**
- `hotel_class` is hotel-only
- `brands` filter is hotel-only

**Use cases:** Family groups, longer stays, full-home rentals, beach/mountain getaways. Present `essential_info` (bedrooms, bathrooms, sleeps) prominently.

### 3. Filtering Searches

Layer filters onto any search to narrow results.

**Price:**
- `min_price`, `max_price` — Per-night price bounds in the requested currency

**Quality:**

| Goal | Parameter | Value |
|------|-----------|-------|
| 3.5+ stars rating | `rating` | `7` |
| 4.0+ stars rating | `rating` | `8` |
| 4.5+ stars rating | `rating` | `9` |
| 2-star hotels | `hotel_class` | `2` |
| 3-star hotels | `hotel_class` | `3` |
| 4-star hotels | `hotel_class` | `4` |
| 5-star hotels | `hotel_class` | `5` |
| 4 or 5 star | `hotel_class` | `4,5` |

**Booking flexibility:**
- `free_cancellation=true` — Only properties offering free cancellation
- `special_offers=true` — Only properties with active deals
- `eco_certified=true` — Only eco-certified properties

**Property/amenity targeting:**
- `property_types` — Numeric codes (resort, motel, B&B, etc. — see SerpApi reference page)
- `amenities` — Numeric codes (pool, gym, free Wi-Fi, parking, etc. — see SerpApi reference page)
- `brands` — Comma-separated brand IDs from the response's `brands[]` array

### 4. Sorting

Default sort is by relevance. Override with `sort_by`:

| Sort | Value | When to Use |
|------|-------|-------------|
| Relevance | (omit) | Default Google ranking |
| Lowest price | `3` | Budget-first searches |
| Highest rating | `8` | Quality-first searches |
| Most reviewed | `13` | Reliability / popularity |

For "best value" requests, sort by `8` (highest rating) and apply `max_price`.

### 5. Property Deep-Dive (property_token)

Once the user picks a property, call `google_hotels` again with `property_token` set to the chosen property's token. Keep `check_in_date` / `check_out_date` so the rates match the original window.

**What the deep-dive returns:**
- Full rates from all booking sources (`prices[]`)
- Complete amenities and excluded amenities
- Room types and availability
- Detailed reviews breakdown by category with snippets
- Nearby places and attractions
- Location highlights

**Presentation pattern:**
1. Headline: name, hotel class, overall rating
2. Best price + cheapest source from `prices[]`
3. Amenities grouped (key amenities highlighted)
4. Top 3 review themes from `reviews_breakdown`
5. Location context (nearby attractions)

### 6. Photo Gallery

Use the `google_hotels_photos` engine with the `property_token` from a search result.

**Response is sectioned** (e.g., "At a glance", "Rooms", "Lobby"). Each section has its own `next_page_token` for paginating that section.

Each photo includes `width`, `height`, `alt`, `source` (Visitor Submitted / Owner Submitted / External Website), `thumbnail_url`, `photo_url`, and `posted_on`.

**Strategy:**
- For overview: pull first section ("At a glance") only
- For specific room/area: find the matching section and paginate it
- Prefer `photo_url` over `thumbnail_url` for display

### 7. Reviews + Subratings

Use the `google_hotels_reviews` engine with the property's `property_token`.

**Sort options:**

| Sort | Value |
|------|-------|
| Most helpful (default) | `1` |
| Most recent | `2` |
| Highest score | `3` |
| Lowest score | `4` |

**Source filter:**
- `source_number=0` — All sources (default)
- `source_number=-1` — Google reviews only

**Category filter:** `category_token` filters reviews to a category (cleanliness, service, location, etc.). Tokens come from the property search response's review breakdown.

**Each review contains:**
- `user` — `name`, `link`, `thumbnail`
- `source` — `"Google"`, `"Tripadvisor"`, `"Booking.com"`, etc.
- `rating`, `best_rating` — Score and scale
- `date` — Relative date string ("2 months ago")
- `snippet` — Review text
- `subratings` — `rooms`, `service`, `location` numeric scores
- `hotel_highlights` — Tags like `"Luxury"`, `"Great value"`
- `attributes` — Named aspects with snippets
- `response` — Hotel's reply (`date`, `snippet`) when present

Paginate with `next_page_token`.

### 8. Autocomplete (Cities, Landmarks, Hotels)

Use `google_hotels_autocomplete` with `q` set to a partial query. Returns suggestions including:
- `value`, `autocomplete_suggestion` — The completed text
- `type` — Category (e.g., `"accommodation"`)
- `location` — Address info
- `thumbnail` — Image URL
- `kgmid`, `data_cid` — Knowledge graph IDs
- `property_token` — If the suggestion is a specific property, this can be used directly with the deep-dive workflow

**When to use:**
- Ambiguous city names (`"Paris"` → Paris, France vs Paris, Texas)
- Resolving a hotel name straight to a `property_token` to skip the search step
- Localized name handling (use `hl` to match user language)

### 9. Comparing Multiple Properties

Side-by-side comparison of 2-4 candidate properties.

**Strategy:**
1. Search once with the user's filters; pick top candidates
2. For each candidate, run a `property_token` deep-dive to get full rates and amenities
3. Optionally fetch reviews summary for each
4. Build comparison table

**Presentation pattern:**

```
🏨 Hotel Comparison — [Dates]

| Property        | Class | Rating | Reviews | Lowest /night | Free Cancel | Pool | Gym |
|-----------------|-------|--------|---------|---------------|-------------|------|-----|
| Hotel A         | ★★★★  | 4.6    | 1,240   | $189          | Yes         | Yes  | Yes |
| Hotel B         | ★★★★★ | 4.8    | 2,105   | $312          | No          | Yes  | Yes |
| Hotel C         | ★★★   | 4.4    | 642     | $129          | Yes         | No   | Yes |

🏆 Best Value: Hotel A — 4-star, 4.6 rating, $189 with free cancellation
🏆 Highest Quality: Hotel B — 4.8 rating, full amenities
🏆 Cheapest: Hotel C — $129, decent ratings, no pool
```

### 10. Price-Sensitive Date Comparison

To find the cheapest dates to stay, run multiple searches varying `check_in_date` / `check_out_date` (same length of stay). Compare the lowest `rate_per_night.extracted_lowest` from each.

Useful for flexible-date trips. Combine with `sort_by=3` (lowest price) for fastest reads.

## Filter Quick Reference

| Goal | Parameter | Value |
|------|-----------|-------|
| Under $200/night | `max_price` | `200` |
| Over $400/night (luxury) | `min_price` | `400` |
| 4+ star rating | `rating` | `8` |
| 4.5+ star rating | `rating` | `9` |
| 4-star hotels | `hotel_class` | `4` |
| 4 or 5 star hotels | `hotel_class` | `4,5` |
| Free cancellation only | `free_cancellation` | `true` |
| Active deals only | `special_offers` | `true` |
| Eco-certified | `eco_certified` | `true` |
| Vacation rentals | `vacation_rentals` | `true` |
| 2+ bedrooms (rental) | `bedrooms` | `2` |
| 2+ bathrooms (rental) | `bathrooms` | `2` |
| Cheapest first | `sort_by` | `3` |
| Highest rated first | `sort_by` | `8` |
| Most reviewed first | `sort_by` | `13` |

## Presenting Results

### Property Search Result Format

For each property in the list:

```
🏨 [Name] — [hotel_class stars or bedrooms/bathrooms for rentals]
   ⭐ [overall_rating] ([reviews] reviews) | 📍 [neighborhood / address]
   💰 $[rate_per_night.lowest]/night · Total: $[total_rate.lowest]
   ✨ [key amenities: Pool, Free Wi-Fi, Breakfast included]
   [Free cancellation · Special offer flags if present]
```

### Property Deep-Dive Format

```
🏨 [Name] — ★★★★ ([overall_rating] · [reviews] reviews)
📍 [address]
🕑 Check-in [check_in_time] · Check-out [check_out_time]

💰 Best Rate: $[lowest]/night via [source]
   Other sources: [Provider A $X, Provider B $Y, Provider C $Z]

✨ Amenities: [top 8-10 amenities]
🚫 Not available: [notable excluded amenities]

📊 Review Themes:
   Service ⭐ [X]: "[snippet]"
   Property ⭐ [X]: "[snippet]"
   Location ⭐ [X]: "[snippet]"

📍 Nearby: [top 3-5 nearby places]
```

## Common Patterns

### "Find me a hotel in [city] for [dates]"
1. Autocomplete the city if ambiguous
2. Search with `q`, `check_in_date`, `check_out_date`, `adults`
3. Present top 5-10 ranked by relevance
4. Offer to filter by price, rating, or amenities

### "Cheapest 4-star hotel in [city]"
1. Search with `hotel_class=4`, `sort_by=3`
2. Present top 5 cheapest
3. Highlight any with `free_cancellation` for booking flexibility

### "Family vacation rental, 3 bedrooms, [city]"
1. Search with `vacation_rentals=true`, `bedrooms=3`, `adults`, `children`, `children_ages`
2. Present rentals with `essential_info` (bedrooms, bathrooms, sleeps)
3. Note amenities especially relevant to families (kitchen, washer, parking)

### "Show me reviews for [hotel]"
1. Autocomplete or search to get `property_token`
2. Call `google_hotels_reviews` with the token
3. Present overall rating, subrating breakdown, and 3-5 standout reviews
4. Optionally filter by `sort_by=2` for most recent or `sort_by=4` to surface complaints

### "Compare these 3 hotels"
1. Resolve each to a `property_token` (search or autocomplete)
2. Deep-dive each via `property_token`
3. Build comparison table with class, rating, price, key amenities, cancellation
4. Recommend based on the user's priority

### "Photos of [hotel]"
1. Get `property_token` (search or autocomplete)
2. Call `google_hotels_photos`
3. Present first section, offer to drill into a specific section (Rooms, Lobby, etc.)

## Tips

- **Always carry dates into the deep-dive.** When passing `property_token` back to `google_hotels`, include the same `check_in_date` / `check_out_date` so rates are accurate for the user's stay.
- **`property_token` is the universal key.** Capture it from any search result — it's how you unlock photos, reviews, and full pricing.
- **Hotel class doesn't apply to rentals.** Don't pass `hotel_class` with `vacation_rentals=true` — use `bedrooms` / `bathrooms` instead.
- **`children_ages` is required when `children > 0`.** Google Hotels uses age to scope room configurations; missing ages can change pricing.
- **Currency awareness.** Default is `USD`. Set `currency` to the user's preferred currency; price filters (`min_price` / `max_price`) operate in that currency.
- **Free cancellation is a strong filter.** It dramatically cuts results — only use when the user explicitly cares.
- **Sponsored vs organic.** Ads appear in a separate `ads[]` array. Properties may also have `sponsored: true`. Flag these to the user when surfacing them.
- **Brand filtering.** The `brands[]` response array provides IDs to use in the `brands` parameter — useful for "show me only Marriott / Hilton / Hyatt" requests.
- **Pagination is token-based.** Use `serpapi_pagination.next_page_token` for the next page, not a numeric `page` parameter.
- **Photos are sectioned.** Each section paginates independently — track separate `next_page_token`s per section.
- **Multi-source review pricing.** `prices[]` on a property typically lists Booking.com, Expedia, Hotels.com, the hotel direct site, etc. The cheapest isn't always the property's official site — surface the spread.
- **`location_rating`** is a separate score from `overall_rating` — useful when location is the user's priority (e.g., "near the convention center").
- **Use autocomplete for hotel names.** Going straight from a hotel name to a `property_token` via autocomplete skips a search round-trip.
