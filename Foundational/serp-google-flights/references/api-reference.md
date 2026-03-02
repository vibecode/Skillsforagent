# SerpApi Google Flights — API Reference

Complete parameter and response documentation for the Google Flights engines.

## Table of Contents

1. [Flight Search Engine Parameters](#flight-search-engine)
2. [Flight Results Response Schema](#flight-results-response)
3. [Return Flights](#return-flights)
4. [Booking Options Response Schema](#booking-options-response)
5. [Price Insights Response Schema](#price-insights-response)
6. [Autocomplete Engine Parameters & Response](#autocomplete-engine)
7. [Multi-City JSON Format](#multi-city-json-format)
8. [Time Range Format](#time-range-format)

---

## Flight Search Engine

**Endpoint:** `GET https://serpapi.com/search?engine=google_flights`

### All Parameters

| Parameter | Required | Type | Description |
|-----------|----------|------|-------------|
| `engine` | Yes | string | Must be `google_flights` |
| `api_key` | Yes | string | SerpApi API key |
| `departure_id` | Yes* | string | Airport code(s) or kgmid(s), comma-separated. *Not needed with `departure_token` or `booking_token` |
| `arrival_id` | Yes* | string | Same format as `departure_id` |
| `outbound_date` | Yes* | string | `YYYY-MM-DD` format |
| `return_date` | Conditional | string | `YYYY-MM-DD`. Required when `type=1` |
| `type` | No | integer | `1` = Round trip (default), `2` = One way, `3` = Multi-city |
| `travel_class` | No | integer | `1` = Economy, `2` = Premium economy, `3` = Business, `4` = First |
| `currency` | No | string | Currency code, default `USD` |
| `gl` | No | string | Two-letter country code |
| `hl` | No | string | Two-letter language code |
| `adults` | No | integer | Default 1 |
| `children` | No | integer | Default 0 |
| `infants_in_seat` | No | integer | Default 0 |
| `infants_on_lap` | No | integer | Default 0 |
| `stops` | No | integer | `0`=Any, `1`=Nonstop, `2`=1 stop or fewer, `3`=2 stops or fewer |
| `include_airlines` | No | string | Comma-separated IATA codes or alliance names |
| `exclude_airlines` | No | string | Same format. Mutually exclusive with `include_airlines` |
| `bags` | No | integer | Carry-on bags count |
| `max_price` | No | integer | Maximum ticket price |
| `max_duration` | No | integer | Maximum flight duration in minutes |
| `outbound_times` | No | string | Departure/arrival time range (see Time Range Format) |
| `return_times` | No | string | Same format, for return leg only |
| `emissions` | No | integer | `1` = Less emissions only |
| `layover_duration` | No | string | Min,max in minutes (e.g. `90,330`) |
| `exclude_conns` | No | string | Connecting airports to exclude (comma-separated codes) |
| `sort_by` | No | integer | `1`=Top, `2`=Price, `3`=Departure, `4`=Arrival, `5`=Duration, `6`=Emissions |
| `deep_search` | No | boolean | `true` for exact browser-match results (slower) |
| `show_hidden` | No | boolean | `true` to include hidden results |
| `exclude_basic` | No | boolean | `true` to exclude basic economy (US domestic only) |
| `multi_city_json` | Conditional | string | JSON array for `type=3` |
| `departure_token` | No | string | Token from outbound results to get return flights |
| `booking_token` | No | string | Token to get booking options |
| `no_cache` | No | boolean | `true` to skip cache (1h TTL). Don't combine with `async` |
| `async` | No | boolean | `true` for async search via Search Archive API |

### Alliance Codes (for `include_airlines` / `exclude_airlines`)

- `STAR_ALLIANCE` — Star Alliance
- `SKYTEAM` — SkyTeam
- `ONEWORLD` — Oneworld

---

## Flight Results Response

### Top-Level Arrays

```json
{
  "search_metadata": { ... },
  "search_parameters": { ... },
  "best_flights": [ ... ],
  "other_flights": [ ... ],
  "price_insights": { ... }
}
```

`best_flights` may not always be present. `other_flights` contains additional options.

### Flight Group Schema

Each element in `best_flights` / `other_flights`:

```json
{
  "flights": [
    {
      "departure_airport": {
        "name": "String — Full airport name",
        "id": "String — 3-letter IATA code",
        "time": "String — YYYY-MM-DD HH:MM"
      },
      "arrival_airport": {
        "name": "String",
        "id": "String",
        "time": "String — YYYY-MM-DD HH:MM"
      },
      "duration": "Integer — minutes",
      "airplane": "String — aircraft model",
      "airline": "String — airline name",
      "airline_logo": "String — URL",
      "travel_class": "String — Economy, Business, etc.",
      "flight_number": "String — e.g. UA 2175",
      "legroom": "String — e.g. 31 in",
      "extensions": ["String — legroom note, Wi-Fi, power, emissions"],
      "ticket_also_sold_by": ["String — other airlines"],
      "overnight": "Boolean — true if overnight",
      "often_delayed_by_over_30_min": "Boolean"
    }
  ],
  "layovers": [
    {
      "duration": "Integer — minutes",
      "name": "String — airport name",
      "id": "String — airport code",
      "overnight": "Boolean"
    }
  ],
  "total_duration": "Integer — total trip minutes",
  "carbon_emissions": {
    "this_flight": "Integer — grams CO2",
    "typical_for_this_route": "Integer — grams CO2",
    "difference_percent": "Integer — positive = above typical"
  },
  "price": "Integer — in selected currency",
  "type": "String — Round trip, One way",
  "airline_logo": "String — URL (multi.png for mixed airlines)",
  "departure_token": "String — use for return flights (round trip)",
  "booking_token": "String — use for booking options (one-way/multi-city)"
}
```

**Note:** Round trip outbound results have `departure_token`. After selecting return flights, results have `booking_token`. One-way and multi-city results have `booking_token` directly.

---

## Return Flights

Use `departure_token` from the outbound search to get return options:

```
GET /search?engine=google_flights&departure_token=TOKEN&api_key=KEY
```

No other date/airport parameters needed — they're encoded in the token. Response structure is the same (`best_flights`, `other_flights`), but results now include `booking_token`.

---

## Booking Options Response

Use `booking_token` to get booking links and prices:

```
GET /search?engine=google_flights&booking_token=TOKEN&api_key=KEY
```

### Response Schema

```json
{
  "selected_flights": [
    {
      "flights": [ ... ],
      "total_duration": 360,
      "carbon_emissions": { ... },
      "type": "Round trip",
      "airline_logo": "...",
      "departure_token": "..."
    }
  ],
  "baggage_prices": {
    "together": ["1 free carry-on", "1st checked bag: 99-187"]
  },
  "booking_options": [
    {
      "together": {
        "book_with": "String — booking source",
        "airline": "Boolean — true if airline direct",
        "airline_logos": ["String — URLs"],
        "marketed_as": ["String — flight numbers"],
        "price": "Integer",
        "local_prices": [{ "currency": "EUR", "price": 173 }],
        "option_title": "String — fare class name",
        "extensions": ["String — fare rules"],
        "baggage_prices": ["String — bag costs"],
        "booking_request": {
          "url": "String — redirect URL",
          "post_data": "String — POST body for booking redirect"
        }
      }
    }
  ]
}
```

Some booking options use `separately` instead of `together` when outbound and return are from different sources. `separately` contains `departing` and `returning` objects with their own `book_with`, `price`, etc.

---

## Price Insights Response

Included alongside flight results in the main search response:

```json
{
  "price_insights": {
    "lowest_price": "Integer — cheapest price among results",
    "price_level": "String — low, typical, or high",
    "typical_price_range": ["Integer — low bound", "Integer — high bound"],
    "price_history": [
      ["Integer — unix timestamp", "Integer — price"],
      ...
    ]
  }
}
```

---

## Autocomplete Engine

**Endpoint:** `GET https://serpapi.com/search?engine=google_flights_autocomplete`

### Parameters

| Parameter | Required | Type | Description |
|-----------|----------|------|-------------|
| `engine` | Yes | string | Must be `google_flights_autocomplete` |
| `api_key` | Yes | string | SerpApi API key |
| `q` | Yes | string | Search query (city, airport, or region) |
| `gl` | No | string | Country code |
| `hl` | No | string | Language code |
| `exclude_regions` | No | boolean | `true` to return only cities, no regions |

### Response: `suggestions[]`

```json
{
  "suggestions": [
    {
      "position": 1,
      "name": "Tokyo, Japan",
      "type": "city",
      "description": "Capital of Japan",
      "id": "/m/07dfk",
      "airports": [
        {
          "name": "Narita International Airport",
          "id": "NRT",
          "city": "Tokyo",
          "city_id": "/m/07dfk",
          "distance": "41 mi"
        },
        {
          "name": "Haneda Airport",
          "id": "HND",
          "city": "Tokyo",
          "city_id": "/m/07dfk",
          "distance": "9 mi"
        }
      ]
    },
    {
      "position": 2,
      "name": "Japan",
      "type": "region",
      "description": "Country in East Asia",
      "id": "/m/03_3d"
    }
  ]
}
```

**`type`**: `"city"` (has `airports` array) or `"region"` (no airports).

**Using results in flight search:** Use `id` (kgmid) as `departure_id` or `arrival_id`, or use `airports[].id` for specific airport codes.

---

## Multi-City JSON Format

Used with `type=3`. A JSON-encoded array of leg objects:

```json
[
  {
    "departure_id": "JFK",
    "arrival_id": "CDG",
    "date": "2026-04-15"
  },
  {
    "departure_id": "CDG",
    "arrival_id": "NRT",
    "date": "2026-04-20",
    "times": "8,18,9,23"
  },
  {
    "departure_id": "NRT",
    "arrival_id": "LAX,SEA",
    "date": "2026-04-27"
  }
]
```

Each leg supports: `departure_id`, `arrival_id` (same formats as main params, comma-separated for multiples), `date` (`YYYY-MM-DD`), and optional `times` (see Time Range Format).

---

## Time Range Format

For `outbound_times`, `return_times`, and multi-city `times`:

**Two values** (departure only): `START_HOUR,END_HOUR`
- `4,18` → 4:00 AM to 7:00 PM departure
- `0,18` → 12:00 AM to 7:00 PM departure
- `19,23` → 7:00 PM to 12:00 AM departure

**Four values** (departure + arrival): `DEP_START,DEP_END,ARR_START,ARR_END`
- `4,18,3,19` → 4AM-7PM departure, 3AM-8PM arrival
- `0,23,3,19` → unrestricted departure, 3AM-8PM arrival

Each number represents the **beginning of an hour**. The end hour means up to the end of that hour (e.g. `18` = up to 6:59 PM, displayed as 7:00 PM).
