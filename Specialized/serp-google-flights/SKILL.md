---
name: serp-google-flights
display_name: Google Flights
description: >
  Specialized skill for Google Flights workflows via SerpApi — flight search, price comparison,
  round-trip planning, multi-city itineraries, and booking. Use when: (1) searching for flights
  between cities or airports, (2) comparing flight prices across dates or airlines, (3) planning
  round-trip travel with outbound and return flights, (4) building multi-city itineraries,
  (5) finding the cheapest flights with filters (nonstop, class, bags, time), (6) analyzing
  price trends and insights for a route, (7) getting booking links for selected flights,
  (8) resolving airport codes from city names, (9) any travel planning task involving flight
  search or airfare. This skill builds on the foundational serpapi skill for all API details.
dependencies:
  - serpapi
metadata: {"openclaw": {"emoji": "✈️"}}
---

# Google Flights Workflows

Flight search, comparison, and booking via the SerpApi Google Flights engine. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engines: `google_flights`, `google_flights_autocomplete`)

## Core Concepts

### Flight Types

| Type | Value | When to Use |
|------|-------|-------------|
| Round trip | `1` (default) | Standard return travel. Requires two searches: outbound → return via `departure_token` |
| One-way | `2` | No return needed |
| Multi-city | `3` | Multiple legs (e.g., NYC→Paris→Tokyo→LA). Uses `multi_city_json` |

### Response Structure

Every flight search returns two arrays:
- **`best_flights`** — Google's recommended flights (best value, convenience, or duration)
- **`other_flights`** — All remaining options

Each flight group contains:
- `flights[]` — Individual legs (departure/arrival airports, times, duration, airline, flight number, airplane, legroom, travel class, extensions)
- `layovers[]` — Connection info (airport, duration, overnight flag)
- `total_duration` — Total journey time in minutes
- `price` — Total price in the requested currency
- `carbon_emissions` — This flight vs typical for the route
- `departure_token` — Used to fetch return flights (round trip only)
- `booking_token` — Used to fetch booking options for a specific flight

### Price Insights

Most searches include `price_insights`:
- `lowest_price` — Cheapest available flight
- `price_level` — `"low"`, `"typical"`, or `"high"` relative to historical data
- `typical_price_range` — `[low, high]` bounds for what's normal on this route
- `price_history` — Array of `[timestamp, price]` pairs showing how prices have moved

Use this to advise whether to book now or wait.

## Workflows

### 1. Simple One-Way Flight Search

Use the **serpapi** skill's wrapper script with the `google_flights` engine. Set `type` to `2` for one-way.

**Key parameters:**
- `departure_id` — Airport code (e.g., `JFK`) or location kgmid (e.g., `/m/0vzm`). Comma-separate for multiple origins.
- `arrival_id` — Same format. Comma-separate for multiple destinations.
- `outbound_date` — `YYYY-MM-DD` format
- `type` — Set to `2`

**Useful filters:**
- `stops` — `1` nonstop only, `2` ≤1 stop, `3` ≤2 stops
- `travel_class` — `1` economy, `2` premium economy, `3` business, `4` first
- `max_price` — Maximum ticket price
- `bags` — Number of carry-on bags (≤ total passengers with bag allowance)
- `include_airlines` / `exclude_airlines` — Comma-separated IATA codes (e.g., `UA,AA`). Also supports alliances: `STAR_ALLIANCE`, `SKYTEAM`, `ONEWORLD`
- `outbound_times` — Departure/arrival time range (e.g., `6,12` for 6AM-1PM departure; `6,12,8,20` for departure and arrival ranges)
- `max_duration` — Maximum flight duration in minutes
- `layover_duration` — Layover range in minutes (e.g., `60,240`)
- `exclude_conns` — Exclude connecting airports (e.g., `ORD,DFW`)
- `emissions` — Set to `1` for lower-emission flights only
- `sort_by` — `1` top flights, `2` price, `3` departure time, `4` arrival time, `5` duration, `6` emissions

**What to present:** Top 3-5 options from `best_flights` + cheapest from `other_flights` if cheaper. Include airline, departure/arrival times, duration, stops, and price.

### 2. Round-Trip Flight Search (Two-Step)

Round trips require **two searches**:

**Step 1 — Outbound flights:**
Search with `type=1` (default), `departure_id`, `arrival_id`, `outbound_date`, and `return_date`. This returns outbound options. Each result includes a `departure_token`.

**Step 2 — Return flights:**
Pick the user's preferred outbound flight and make a second search passing its `departure_token`. This returns matching return flights for that outbound selection.

**Important:** The `departure_token` locks in the outbound choice. You must present outbound options first, let the user pick (or pick the best match), then fetch returns.

**Presentation pattern:**
1. Search outbound → present top options with price, times, stops
2. User picks outbound (or you recommend the best value)
3. Search with `departure_token` → present return options
4. Combine outbound + return for total trip summary

### 3. Multi-City Itinerary

Set `type=3` and provide `multi_city_json` — a JSON string containing flight leg objects:

```json
[
  {"departure_id": "JFK", "arrival_id": "CDG", "date": "2026-05-01"},
  {"departure_id": "CDG", "arrival_id": "NRT", "date": "2026-05-08"},
  {"departure_id": "NRT", "arrival_id": "JFK", "date": "2026-05-15"}
]
```

Each object supports:
- `departure_id`, `arrival_id` — Airport codes or kgmids (comma-separate for multiple)
- `date` — `YYYY-MM-DD`
- `times` — Optional, same format as `outbound_times` (e.g., `8,18,9,23`)

**Multi-city also uses `departure_token`** — the first search returns results for the first leg. Use the `departure_token` from the chosen first-leg flight to get the second leg, and so on.

### 4. Price Comparison Across Dates

To find the cheapest date to fly, run multiple searches varying `outbound_date` (and `return_date` for round trips). Compare `price_insights.lowest_price` across searches.

**Strategy:**
- Search 3-5 date combinations around the user's preferred dates (±1-3 days)
- Compare `lowest_price` and `price_level` from each
- Present a date comparison table:

```
| Dates              | Lowest Price | Price Level | vs Typical       |
|--------------------|-------------|-------------|------------------|
| Mar 15-22          | $245        | low         | $200-$400 range  |
| Mar 16-23          | $312        | typical     | $200-$400 range  |
| Mar 17-24          | $189        | low         | $200-$400 range  |
```

**Tip:** Enable `deep_search=true` for the most accurate price comparison, though it's slower.

### 5. Getting Booking Links

Once the user selects a flight, use the `booking_token` from that flight result to fetch booking options:

Pass `booking_token` to a new search. The response includes:
- `selected_flights` — Confirmation of the chosen itinerary
- `booking_options[]` — List of booking providers with:
  - `together.book_with` — Provider name
  - `together.airline_logos` — Airline logos
  - `together.price` — Price
  - `together.booking_request` — Deep link to book
  - `separate_tickets` — Whether legs are booked separately (watch for this — separate tickets mean no rebooking protection)

**Present booking options** sorted by price, noting any separate-ticket warnings.

### 6. Airport Code Resolution

When the user provides a city name instead of an airport code, use the `google_flights_autocomplete` engine:

Search with `q` set to the city name. Returns airport codes and kgmids.

**When to use kgmids vs airport codes:**
- **Airport codes** (e.g., `JFK`, `LAX`) — Use for specific airports
- **Location kgmids** (e.g., `/m/0vzm` for Austin, TX) — Use for cities with multiple airports. Google will search all airports in that city.
- **Multiple airports** — Comma-separate: `JFK,EWR,LGA` to search all NYC-area airports

### 7. Deep Search for Accurate Results

By default, results are fast but may differ from Google Flights in the browser. Set `deep_search=true` for browser-identical results at the cost of slower response times.

**When to use deep search:**
- Price comparison where accuracy matters
- User reports results don't match what they see on Google Flights
- Final booking decision — verify prices before presenting booking links

**When to skip deep search:**
- Initial exploration / browsing options
- Date comparison (running many searches — speed matters more)
- Casual "what does it cost to fly to X?" queries

## Filter Quick Reference

| Goal | Parameter | Value |
|------|-----------|-------|
| Nonstop only | `stops` | `1` |
| ≤1 stop | `stops` | `2` |
| Business class | `travel_class` | `3` |
| Under $500 | `max_price` | `500` |
| Morning departures | `outbound_times` | `6,12` |
| Red-eye flights | `outbound_times` | `20,23` |
| Specific airlines | `include_airlines` | `UA,AA,DL` |
| Exclude budget carriers | `exclude_airlines` | `NK,F9,WN` |
| Star Alliance only | `include_airlines` | `STAR_ALLIANCE` |
| Short layovers | `layover_duration` | `60,180` |
| Under 10 hours | `max_duration` | `600` |
| Low emissions | `emissions` | `1` |
| With checked bags | `bags` | `1` |
| Sort by price | `sort_by` | `2` |

## Presenting Results

### Flight Summary Format

For each flight option, present:

```
✈️ [Airline] [Flight#] — $[Price]
   [Departure Airport] [Time] → [Arrival Airport] [Time]
   Duration: [Xh Ym] | Stops: [N] | Class: [Economy/Business/etc.]
   [Notable: nonstop, overnight, emissions info, legroom]
```

### Price Insights Summary

When `price_insights` is available:

```
💰 Price Analysis: [Route]
   Current lowest: $[X] ([low/typical/high])
   Typical range: $[low]-$[high]
   Recommendation: [Book now — prices are below typical / Wait — prices are above typical / Good time to book — prices are in normal range]
```

### Booking Summary

```
🎫 Booking Options for [Route]:
   1. [Provider] — $[Price] [⚠️ separate tickets]
   2. [Provider] — $[Price]
   Book: [URL]
```

## Common Patterns

### "Find me the cheapest flight from X to Y"
1. Resolve airport codes if city names given (autocomplete)
2. One-way search sorted by price (`sort_by=2`)
3. Present top 3-5 cheapest, noting trade-offs (stops, duration, timing)

### "Plan a trip from X to Y, dates flexible"
1. Date comparison: search ±3 days around preferred dates
2. Present date comparison table with price insights
3. Once dates chosen, full round-trip workflow (outbound → return)
4. Offer booking links for final selection

### "Business class options for X to Y"
1. Search with `travel_class=3`, potentially `deep_search=true`
2. Present options emphasizing amenities (from `extensions`: legroom, Wi-Fi, power, lounge access)
3. Compare against first class (`travel_class=4`) if user might upgrade

### "Multi-city: NYC → London → Rome → NYC"
1. Autocomplete to resolve codes if needed
2. Multi-city search with `multi_city_json`
3. Step through each leg using `departure_token`
4. Present complete itinerary with total price

## Tips

- **Always resolve ambiguous cities.** "London" could be LHR, LGW, STN, LTN, LCY. Use autocomplete or the city's kgmid to search all airports.
- **Comma-separate airports** for flexible origin/destination. `JFK,EWR,LGA` covers all NYC airports.
- **Check `carbon_emissions`** if the user cares about sustainability. The response shows this flight vs typical for the route.
- **Watch for `overnight` flags** on layovers and legs — important for the user's comfort planning.
- **`often_delayed_by_over_30_min`** appears on legs with reliability issues — flag this for the user.
- **Separate tickets warning:** When `booking_token` results show `separate_tickets: true`, warn the user they'll have separate bookings with no rebooking protection if one leg is disrupted.
- **Currency:** Default is USD. Set `currency` parameter for other currencies (e.g., `EUR`, `GBP`, `JPY`).
- **Localization:** Use `gl` and `hl` to match the user's country and language for more relevant results.
- **`show_hidden=true`** reveals flights Google normally hides (long layovers, unusual routings). Use when the user wants exhaustive options.
- **`exclude_basic=true`** filters out basic economy fares (no seat selection, no carry-on). Only works for US domestic flights with `gl=us`.
