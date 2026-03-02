---
name: serp-google-flights
description: >
  Foundational skill for the SerpApi Google Flights API — search flights, get return legs,
  view booking options, check price insights, and autocomplete airports/cities. Use when:
  (1) searching for flights between airports or cities, (2) comparing flight prices, durations,
  and airlines, (3) finding round-trip, one-way, or multi-city flights, (4) getting return
  flight options using departure tokens, (5) retrieving booking links and baggage pricing
  via booking tokens, (6) checking price insights (lowest price, typical range, price history),
  (7) looking up airport codes or city IDs with autocomplete, (8) filtering flights by stops,
  airlines, bags, travel class, time ranges, emissions, or max price, (9) any task involving
  Google Flights data through SerpApi. This is the base Google Flights skill — specialized
  skills may reference it for travel planning, fare monitoring, or trip optimization workflows.
metadata: {"openclaw": {"emoji": "✈️", "requires": {"env": ["SERPAPI_KEY"]}, "primaryEnv": "SERPAPI_KEY"}}
---

# SerpApi Google Flights

Search flights, get booking options, and check price trends through SerpApi's structured JSON API. Two engines cover all Google Flights data needs.

## Setup

Requires `SERPAPI_KEY` environment variable. All requests are GET to `https://serpapi.com/search` with `api_key` parameter.

## Engines Overview

| Engine | Purpose |
|--------|---------|
| `google_flights` | Search flights, get return legs, booking options, price insights |
| `google_flights_autocomplete` | Look up airport codes and city/region IDs |

---

## 1. Flight Search

### Basic Search (Round Trip)

```bash
curl -s "https://serpapi.com/search?engine=google_flights&departure_id=JFK&arrival_id=LAX&outbound_date=2026-04-15&return_date=2026-04-22&api_key=$SERPAPI_KEY"
```

### One-Way Search

```bash
curl -s "https://serpapi.com/search?engine=google_flights&departure_id=SFO&arrival_id=ORD&outbound_date=2026-04-15&type=2&api_key=$SERPAPI_KEY"
```

### Multi-City Search

Set `type=3` and provide `multi_city_json`:

```bash
curl -s "https://serpapi.com/search?engine=google_flights&type=3&multi_city_json=[{\"departure_id\":\"JFK\",\"arrival_id\":\"CDG\",\"date\":\"2026-04-15\"},{\"departure_id\":\"CDG\",\"arrival_id\":\"FCO\",\"date\":\"2026-04-20\"}]&api_key=$SERPAPI_KEY"
```

Each object in the array takes: `departure_id`, `arrival_id`, `date`, and optionally `times`.

### Core Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `departure_id` | Yes | Airport code (e.g. `JFK`) or location kgmid (e.g. `/m/02_286`). Comma-separate multiples |
| `arrival_id` | Yes | Same format as `departure_id` |
| `outbound_date` | Yes | `YYYY-MM-DD` format |
| `return_date` | Round trip | Required when `type=1` (default) |
| `type` | No | `1` = Round trip (default), `2` = One way, `3` = Multi-city |
| `travel_class` | No | `1` = Economy (default), `2` = Premium economy, `3` = Business, `4` = First |
| `currency` | No | Currency code (default `USD`). See Google Travel Currencies |
| `gl` | No | Country code (e.g. `us`, `uk`, `de`) |
| `hl` | No | Language code (e.g. `en`, `es`, `fr`) |

### Passenger Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `adults` | 1 | Number of adults |
| `children` | 0 | Number of children |
| `infants_in_seat` | 0 | Infants with their own seat |
| `infants_on_lap` | 0 | Infants on lap |

### Filter Parameters

| Parameter | Description |
|-----------|-------------|
| `stops` | `0` = Any (default), `1` = Nonstop, `2` = 1 stop or fewer, `3` = 2 stops or fewer |
| `include_airlines` | Comma-separated IATA codes (e.g. `UA,AA`). Also: `STAR_ALLIANCE`, `SKYTEAM`, `ONEWORLD` |
| `exclude_airlines` | Same format. Cannot combine with `include_airlines` |
| `bags` | Number of carry-on bags (max = passengers with bag allowance) |
| `max_price` | Maximum ticket price |
| `max_duration` | Maximum flight duration in minutes |
| `outbound_times` | Time range: `4,18` = 4AM-7PM departure; `4,18,3,19` = departure + arrival range |
| `return_times` | Same format, for return leg (round trip only) |
| `emissions` | `1` = Less emissions only |
| `layover_duration` | Range in minutes: `90,330` = 1h30m to 5h30m |
| `exclude_conns` | Exclude connecting airports (comma-separated codes) |
| `sort_by` | `1` = Top flights (default), `2` = Price, `3` = Departure, `4` = Arrival, `5` = Duration, `6` = Emissions |

### Advanced Options

| Parameter | Description |
|-----------|-------------|
| `deep_search` | `true` for browser-identical results (slower). Default `false` |
| `show_hidden` | `true` to include hidden results. Default `false` |
| `exclude_basic` | `true` to exclude basic economy (US domestic only, `gl=us`, `travel_class=1`) |

---

## 2. Response Structure

### Flight Results

The response contains two arrays: `best_flights` (curated top picks) and `other_flights` (remaining options). Both have the same structure.

Each flight group contains:

```
{
  "flights": [...],        // Array of flight legs
  "layovers": [...],       // Layover info between legs
  "total_duration": 360,   // Total trip time in minutes
  "carbon_emissions": {
    "this_flight": 150000,
    "typical_for_this_route": 140000,
    "difference_percent": 7
  },
  "price": 450,
  "type": "Round trip",
  "airline_logo": "https://...",
  "departure_token": "...",  // Use to get return flights
  "booking_token": "..."     // Use to get booking options (one-way/multi-city)
}
```

Each individual flight leg:

| Field | Description |
|-------|-------------|
| `departure_airport` | `{ name, id, time }` — time is `YYYY-MM-DD HH:MM` |
| `arrival_airport` | `{ name, id, time }` |
| `duration` | Flight duration in minutes |
| `airplane` | Aircraft model (e.g. `Boeing 787`) |
| `airline` | Airline name |
| `airline_logo` | URL to airline logo |
| `travel_class` | `Economy`, `Business`, etc. |
| `flight_number` | e.g. `UA 2175` |
| `legroom` | e.g. `31 in` |
| `extensions` | Array: legroom notes, Wi-Fi, power, emissions estimate |
| `ticket_also_sold_by` | Other airlines selling this flight |
| `overnight` | `true` if overnight flight |
| `often_delayed_by_over_30_min` | `true` if frequently delayed |

Each layover: `{ duration, name, id, overnight }` — duration in minutes.

### Price Insights

Returned alongside flight results:

```json
{
  "price_insights": {
    "lowest_price": 285,
    "price_level": "low",
    "typical_price_range": [280, 420],
    "price_history": [[1691013600, 575], [1691100000, 575], ...]
  }
}
```

- `price_level`: `"low"`, `"typical"`, or `"high"`
- `price_history`: Array of `[unix_timestamp, price]` pairs

---

## 3. Return Flights (Round Trip)

For round trips, the initial search returns outbound flights with `departure_token`. Use it to get return options:

```bash
curl -s "https://serpapi.com/search?engine=google_flights&departure_token=TOKEN_HERE&api_key=$SERPAPI_KEY"
```

The response has the same `best_flights` / `other_flights` structure, now with `booking_token` on each result.

---

## 4. Booking Options

Once you have a `booking_token` (from one-way results or return flight results):

```bash
curl -s "https://serpapi.com/search?engine=google_flights&booking_token=TOKEN_HERE&api_key=$SERPAPI_KEY"
```

### Response

**`selected_flights`** — Array confirming the full itinerary (outbound + return legs).

**`baggage_prices`** — Baggage cost info:
```json
{
  "together": ["1 free carry-on", "1st checked bag: 99-187"]
}
```

**`booking_options`** — Array of booking sources:

| Field | Description |
|-------|-------------|
| `together.book_with` | Booking source name |
| `together.airline` | `true` if booking directly with airline |
| `together.price` | Price in selected currency |
| `together.local_prices` | Array of `{ currency, price }` in local currencies |
| `together.option_title` | Fare class (e.g. `Basic Economy`, `Economy`) |
| `together.extensions` | Fare rules (refunds, changes, seat selection) |
| `together.baggage_prices` | Baggage costs for this option |
| `together.booking_request` | `{ url, post_data }` for the booking redirect |

Some results have `separately` instead of `together` when outbound/return are booked from different sources.

---

## 5. Autocomplete (Airport / City Lookup)

```bash
curl -s "https://serpapi.com/search?engine=google_flights_autocomplete&q=tokyo&api_key=$SERPAPI_KEY"
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `q` | Yes | Search query (city, airport, or region name) |
| `gl` | No | Country code |
| `hl` | No | Language code |
| `exclude_regions` | No | `true` to return only cities (no countries/regions) |

### Response: `suggestions[]`

Each suggestion:

| Field | Description |
|-------|-------------|
| `position` | Rank in results |
| `name` | Location name (e.g. `Tokyo, Japan`) |
| `type` | `city` or `region` |
| `description` | Brief description |
| `id` | Location kgmid (e.g. `/m/07dfk`) — use as `departure_id` or `arrival_id` |
| `airports` | Array of nearby airports (city type only) |

Each airport: `{ name, id, city, city_id, distance }` — `id` is the 3-letter IATA code.

---

## Common Workflows

### Search → Select → Book

1. Search flights (get `best_flights` / `other_flights`)
2. For round trip: use `departure_token` to get return flights
3. Use `booking_token` to get booking options with prices and links

### Find Cheapest Flights

1. Search with `sort_by=2` (price sort)
2. Check `price_insights.lowest_price` and `price_insights.price_level`
3. Compare `price_insights.typical_price_range` to decide if it's a good deal

### Monitor Fare Trends

1. Search the same route periodically with `no_cache=true`
2. Track `price_insights.price_history` for historical trend
3. Compare `price_insights.price_level` over time

### Look Up Unknown Airport Codes

1. Use autocomplete: `engine=google_flights_autocomplete&q=CITY_NAME`
2. Get airport `id` from `suggestions[].airports[].id`
3. Use that code in flight search

### Multi-City Trip Planning

1. Use `type=3` with `multi_city_json` containing each leg
2. Results include `booking_token` for direct booking

## Error Handling

- Check `search_metadata.status` — should be `"Success"`
- If no flights found, try: increasing `max_duration` by ~200 min, adjusting dates, relaxing `stops` filter
- `no_cache=true` forces fresh results (costs 1 credit). Don't combine with `async`
- `departure_token` and `booking_token` are single-use and expire — re-search if they fail

## Detailed Reference

For complete response schemas, all parameter options, and extended JSON examples: see [references/api-reference.md](references/api-reference.md).
