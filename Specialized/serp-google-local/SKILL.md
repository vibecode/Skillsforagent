---
name: serp-google-local
display_name: Google Local
description: >
  Specialized skill for Google Local workflows via SerpApi — searching the local pack
  (the map + business listings that appear inside regular Google web search results),
  business detail lookup, rating-based ranking, and local SEO research. Use when:
  (1) finding local businesses by keyword and city (e.g., "coffee shops in Austin"),
  (2) extracting the local pack / 3-pack that appears in Google search results,
  (3) ranking businesses in a city by rating, review count, or position,
  (4) pulling business contact info (phone, address, hours) for a category,
  (5) doing local SEO research — who appears in the local pack for a given query,
  (6) comparing the local pack against the Google Maps engine for the same query,
  (7) navigating "discover more places" related-business suggestions,
  (8) looking up Google Local Services ads for home/professional services (US-only),
  (9) batch-collecting local businesses across multiple cities, (10) resolving a
  business via ludocid (Google CID) or place_id from prior searches, (11) any task
  involving Google's local search results outside of the dedicated Maps engine.
  This skill builds on the foundational serpapi skill for all API details.
dependencies:
  - serpapi
metadata: {"openclaw": {"emoji": "📍"}}
---

# Google Local Workflows

Local business search, local pack extraction, and local SEO research via SerpApi's Google Local engine. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engines: `google_local`, `google_local_services`)

## Core Concepts

### `google_local` vs `google_maps`

These are **two different SerpApi engines** that return overlapping but distinct data. Pick the right one:

| Engine | What It Returns | When to Use |
|--------|-----------------|-------------|
| `google_local` | The **local pack** that appears inside a regular Google web search ("3-pack" + extended local results, ads, discover more places). Closer to what users see when they Google "pizza near me". | Local SEO research, capturing what shows in normal Google search, paginated local listings tied to web search ranking. |
| `google_maps` | Results from the dedicated **Google Maps** product — richer per-business data, larger result sets, map-tile navigation. | Deep business profiles, exhaustive map browsing, lat/lng radius searches via `ll`, place details endpoints. |
| `google_local_services` | **Local Services Ads** (US only) — vetted home/professional service providers (electricians, plumbers, locksmiths). | Finding "Google Guaranteed" pros, service-area businesses, lead-gen research. Different schema entirely. |

**Rule of thumb:** Use `google_local` when the user cares about *Google search* rankings; use `google_maps` when they care about *map exploration* or need richer business detail.

### Required vs Optional Parameters (`google_local`)

**Required:**
- `q` — Query string (e.g., `"coffee shops"`, `"plumbers"`, `"sushi near union square"`)

**Strongly recommended:**
- `location` — City/region-level location (e.g., `"Austin, Texas, United States"`). Don't pair with `uule`.

**Other key params:**

| Param | Purpose |
|-------|---------|
| `uule` | Google-encoded location string. Alternative to `location`; pick one. |
| `google_domain` | Defaults to `google.com`. Use `google.co.uk`, `google.fr`, etc. for localized results. |
| `gl` | Two-letter country code (`us`, `gb`, `fr`). |
| `hl` | Two-letter language code (`en`, `es`, `de`). |
| `ludocid` | Google CID for a specific place. Pin results to one business. |
| `lsig` | Companion knowledge-graph signature; often paired with `ludocid`. |
| `tbs` | Advanced search filters not exposed in `q`. |
| `start` | Pagination offset (typically increments of `20`). |
| `device` | `desktop` (default), `tablet`, or `mobile`. |

### Response Structure

A `google_local` search returns:

- **`search_metadata`** — Status, IDs, timestamps, the raw `google_local_url`.
- **`search_parameters`** — Echo of what was sent.
- **`ads_results[]`** — Sponsored local listings (when present).
- **`local_results[]`** — The organic local pack.
- **`discover_more_places[]`** — Related business categories Google suggests.
- **`local_map`** — Map preview image URL.
- **`pagination`** — `current`, `next`, plus `serpapi_pagination` for clean follow-up URLs.

Each entry in `local_results[]` typically includes:

| Field | Description |
|-------|-------------|
| `position` | 1-indexed rank in the local pack. |
| `title` | Business name. |
| `place_id` | Stable Google place identifier — use for follow-up lookups. |
| `lsig` | Knowledge-graph signature; combine with `ludocid` for pinned queries. |
| `rating` | Average star rating (float, 0-5). |
| `reviews` | Total review count (int). |
| `price` | Price tier (`$`, `$$`, `$$$`, `$$$$`) when applicable. |
| `type` | Primary business category (e.g., `Coffee shop`, `Italian restaurant`). |
| `address` | Street address as displayed. |
| `phone` | Contact phone. |
| `hours` | Current-day hours string (e.g., `"Open ⋅ Closes 9 PM"`). |
| `gps_coordinates` | `{latitude, longitude}` object. |
| `thumbnail` / `thumbnail_large` | Business photo URLs. |
| `service_options` | Flags like `dine_in`, `takeout`, `delivery`, `curbside_pickup`. |
| `extensions` | Inline tags (e.g., `"Dine-in"`, `"Outdoor seating"`). |
| `links` | Website / directions / order links when present. |
| `provider_id` | Source provider when surfaced (e.g., for accommodations). |

### Pagination

Local results page in increments of `20`. To walk a query:
- Page 1 → omit `start` (or `start=0`)
- Page 2 → `start=20`
- Page 3 → `start=40`

Google typically caps at 5-10 pages of local results. Check `pagination.next` to detect end of results.

### `google_local_services` (Separate Engine)

For US-only home/professional services advertisers ("Google Guaranteed" pros).

**Required:** `engine=google_local_services`, `q` (service name), `data_cid` (Google CID for a city/district — **not** a business CID).

**Optional:** `job_type` (subcategory like `restore_power` for electricians), `hl`, plus `cid`/`bid`/`pid` together to fetch a single provider's profile.

**Response key:** `local_ads[]` — entries include `title`, `rating`, `reviews`, `phone`, `badge` (e.g., `GOOGLE GUARANTEED`), `type`, `service_area`, `years_in_business`, `bookings_nearby`, `hours`, `thumbnail`, plus `cid`/`bid`/`pid` identifiers for detail follow-ups.

**Limitation:** Returns empty outside the US. Place `place_id` was discontinued — always use `data_cid`.

## Workflows

### 1. Local Business Search by Keyword + City

The bread-and-butter use case: "find me [type of business] in [city]".

Use the **serpapi** skill's wrapper script with `engine=google_local`. Pass `q` for the category and `location` for the city.

**Minimum recipe:**
- `q` — Plain-English query (e.g., `"ramen"`, `"24-hour pharmacy"`, `"vegan brunch"`)
- `location` — City + state/country (e.g., `"Brooklyn, New York, United States"`)
- `hl=en`, `gl=us` for US English results

**Presentation pattern:**
1. Show the top 5-10 from `local_results[]` sorted by `position` (Google's ranking).
2. For each: title, rating + reviews, type, address, phone, current hours.
3. Surface `extensions` / `service_options` when relevant (e.g., "Dine-in, Takeout").
4. Append `discover_more_places[]` as related categories the user might also want.

### 2. Local Pack Capture for SEO Research

When the user wants to know **who shows up in Google's local 3-pack** for a given query in a given market.

**Strategy:**
1. Run `google_local` with the user's query + target location.
2. Top 3 entries of `local_results[]` = the local 3-pack visible on Google search.
3. Positions 4-20 = the "more places" expansion.
4. `ads_results[]` = paid local listings (typically above the pack).

**What to report:**
- Who occupies positions 1, 2, 3 (the visible pack)
- Their rating + review count (drives ranking)
- Any LSA / sponsored placements
- Categories in `type` — useful for understanding how Google classifies the query

### 3. Rating-Based Ranking

Google's `position` reflects Google's ranking signals (proximity, prominence, relevance) — **not raw rating**. To rank by user satisfaction instead:

1. Fetch `local_results[]` (paginate if needed).
2. Re-sort client-side by `rating` (descending), with `reviews` as tiebreaker.
3. Filter out anything below a review threshold (e.g., `reviews >= 50`) to avoid lucky single-5-star outliers.

**Bayesian-ish quick ranking:** `rating * log(reviews + 1)` gives a usable confidence-weighted score that rewards both quality and volume.

### 4. Business Detail Lookup via place_id / ludocid

Once you have a `place_id` (from a prior local search) or a Google CID (`ludocid`), you can pin a search to that single business.

**Two paths:**
- **Pinned `google_local` search:** Re-run with the same `q` + `location` plus `ludocid` (and `lsig` if available). Result set narrows to that place.
- **Switch to `google_maps`:** For deeper data (full review texts, photo arrays, "people also search for"), pass the `place_id` to the `google_maps` engine instead. See the maps-specific skill if available.

**When to switch engines:** If the user asks for "reviews", "full hours week", "menu", or "photos of [place]", `google_maps` (or `google_maps_reviews`) is usually the right tool.

### 5. Hours & Contact Extraction

For "what's the phone number / hours for X" style asks:

1. Run a tight `google_local` query — `q="[Business Name]"` + `location="[City]"`.
2. Take `local_results[0]` (assuming title matches).
3. Pull `phone`, `address`, `hours`, and `links` (which often contains the website).
4. If `hours` only shows today's status, the **full weekly hours** require a `google_maps` follow-up via `place_id`.

### 6. Multi-City Batch Collection

For market research across cities (e.g., "list all the boutique hotels in 5 US cities"):

**Strategy:**
1. Loop the cities, running one `google_local` call per city with the same `q` and varying `location`.
2. For each city, paginate via `start=0, 20, 40, ...` until `pagination.next` is absent.
3. Dedupe across cities by `place_id`.
4. Aggregate into a single table.

**Cost note:** Each city × each page = one SerpApi credit. Cap pages per city (3-5 is usually enough for the top of the pack).

### 7. Local Pack vs Maps Comparison

When the user is doing SEO/visibility work and wants to know the *gap* between Google search local pack and Google Maps rankings:

1. Run `google_local` → capture `local_results[]` positions.
2. Run `google_maps` with the same `q` + `ll` (lat/lng) → capture `local_results[]` positions there.
3. Cross-reference by `place_id`.
4. Highlight businesses that rank well on Maps but not in the local pack (or vice versa) — these are SEO opportunities.

### 8. Discover-More-Places Navigation

`discover_more_places[]` surfaces related categories Google associates with the query. Use it to:
- Suggest adjacent searches ("you searched 'ramen' — also try 'noodle bar', 'izakaya', 'Japanese pub'").
- Expand a recommendation set when the initial query is too narrow.
- Build category trees for a market.

### 9. Local Services Lookup (US Home/Pro Services)

Switch to the `google_local_services` engine when the user asks for a vetted home pro (plumber, electrician, locksmith, HVAC, garage door, etc.).

**Recipe:**
1. Resolve the target city's `data_cid` (Google CID). Hardcode common ones or look up via a prior search.
2. Call `google_local_services` with `q="[service]"` and `data_cid=[cid]`.
3. Optionally narrow with `job_type` (e.g., `restore_power`, `install_replace`).
4. Surface `badge` ("GOOGLE GUARANTEED" is the trust signal), `rating`, `reviews`, `years_in_business`, `service_area`, `phone`.
5. For a deep dive on one provider, re-call with `cid` + `bid` + `pid` together.

**Limits:** USA only. Outside the US, fall back to `google_local`.

## Common Patterns

### "Best [thing] in [city]"
1. `google_local` with `q="[thing]"`, `location="[city]"`.
2. Take `local_results[]`, re-sort by `rating * log(reviews + 1)`, filter `reviews >= 30`.
3. Present top 5 with rating, review count, price tier, address, current hours.

### "What's the phone number for [business] in [city]?"
1. `google_local` with `q="[business name]"`, `location="[city]"`.
2. Return `local_results[0].phone` + address as confirmation.
3. If no match in position 1, present top 3 for disambiguation.

### "Who ranks in the local pack for '[query]' in [city]?"
1. `google_local` with the query + city.
2. Report positions 1-3 (the visible pack) with title, rating, reviews, type.
3. Note any `ads_results[]` placements above the pack.
4. Optionally compare across `device=desktop` vs `device=mobile` — local pack composition can differ.

### "List every [category] in [city]"
1. Paginate `google_local` with `start=0, 20, 40, ...` until exhausted.
2. Dedupe by `place_id`.
3. Note Google typically caps at ~60-200 results per query — for exhaustive coverage, use `google_maps` instead.

### "Find a Google Guaranteed plumber near [city]"
1. `google_local_services` with `q="plumber"` + the city's `data_cid`.
2. Filter `badge == "GOOGLE GUARANTEED"`.
3. Sort by `rating` then `bookings_nearby` (a popularity signal).
4. Present top 3-5 with phone, service area, years in business.

## Presenting Local Pack Results

For each business, use a compact card format:

```
📍 [Position]. [Title]  ⭐ [Rating] ([Reviews] reviews)  [Price]
   [Type] · [Address]
   📞 [Phone] · 🕐 [Hours]
   [Extensions: e.g., "Dine-in · Takeout · Outdoor seating"]
```

For local SEO summaries:

```
📍 Local Pack for "[query]" in [city]
   1. [Title] ⭐ [Rating] ([Reviews]) — [Type]
   2. [Title] ⭐ [Rating] ([Reviews]) — [Type]
   3. [Title] ⭐ [Rating] ([Reviews]) — [Type]

   Paid placements: [N] LSA ads above the pack
   Related categories: [discover_more_places joined]
```

For Local Services Ads:

```
🛠️ Local Services — [service] in [city]
   1. [Title] ⭐ [Rating] ([Reviews]) · 🛡️ [Badge]
      [Years] yrs · [Bookings nearby] bookings nearby
      📞 [Phone] · Serves [Service Area]
```

## Tips

- **`location` matters more than `q`.** A vague query with a precise `location` returns sensible results; a precise query with no location returns geographically random ones. Always set `location`.
- **Don't mix `location` and `uule`** — pick one. `uule` is for when you need exact lat/lng-level positioning that `location` can't express.
- **`device=mobile`** often returns a different local pack than `desktop`. If the user is researching mobile visibility, run both.
- **`place_id` is your handoff key** — capture it whenever you find a target business; it unlocks `google_maps`, `google_maps_reviews`, and pinned re-queries.
- **`ludocid` + `lsig` together** pin a query to a single business inside a broader search context. Use when verifying that a specific business still ranks for a query.
- **Reviews drive rank.** When two businesses have similar ratings, the one with more reviews almost always ranks higher in the local pack.
- **Local pack caps at ~3 organic + ads on the SERP itself.** SerpApi returns the expanded set (up to ~20 per page), but the user-visible pack is just the top 3.
- **Switch to `google_maps` for:** exhaustive results, lat/lng radius search via `ll`, full review threads, complete weekly hours, photo arrays.
- **`google_local_services` is US-only** and uses a *city-level* `data_cid`, not a business CID. Don't confuse the two.
- **Pagination is cheap but capped.** Don't over-paginate `google_local` — Google rarely returns more than ~5 pages of meaningful local results.
- **`hours` is current-day only** in `local_results`. For full-week hours, follow up via `google_maps` with the `place_id`.
- **`gl` and `hl` shape ranking subtly.** A `gl=fr` + `hl=fr` search for the same query in Paris ranks differently than `gl=us` + `hl=en` — match the user's market.
