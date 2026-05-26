---
name: serp-google-lens
display_name: Google Lens
description: >
  Specialized skill for Google Lens reverse image search via SerpApi — product identification
  from photos, visual similarity matching, exact-match detection, landmark recognition, plant
  and animal ID, fashion lookup, and source-tracing for images. Use when: (1) reverse-searching
  an image to find its original source or where else it appears online, (2) identifying a product
  from a photo and finding sellers, prices, and in-stock status, (3) finding visually similar
  images, products, or designs, (4) detecting exact matches of an image across the web,
  (5) identifying landmarks, buildings, or places from photos, (6) identifying plants, flowers,
  animals, or insects from photos, (7) looking up fashion items, outfits, shoes, or accessories
  from photos, (8) comparing Google Lens against traditional Google reverse image search,
  (9) refining visual results with a text query (e.g., "blue version", "vintage"),
  (10) any task that starts from an image URL and needs identification, attribution, or shopping
  matches. This skill builds on the foundational serpapi skill for all API details.
dependencies:
  - serpapi
metadata: {"openclaw": {"emoji": "🔎"}}
---

# Google Lens Workflows

Reverse image search, product identification, and visual matching via the SerpApi Google Lens engine. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engines: `google_lens`, `google_reverse_image`)

## Core Concepts

### Image URL Requirement

Google Lens needs a **publicly accessible image URL** — not a local file. The image must be reachable by SerpApi's servers.

| Source | How to Use |
|---|---|
| Image already online | Pass the direct URL as `url` |
| Local file | Upload to a host first (Imgur, S3, public bucket), then pass that URL |
| Data URI / base64 | Not supported — must be a real URL |
| Image behind auth | Not supported — must be public |

Use a direct image link (ends in `.jpg`, `.png`, `.webp`, etc.) rather than a page that embeds the image.

### Search Type Filter (`type`)

The `type` parameter is **required** and controls what results are returned:

| Value | Returns | Use For |
|-------|---------|---------|
| `all` | Mixed results across categories | First-pass exploration; you don't know what the image contains |
| `products` | Commerce-focused matches with sellers and prices | Shopping, "where to buy", product ID |
| `exact_matches` | Pages containing the identical image | Source-tracing, attribution, copyright/leak detection |
| `visual_matches` | Visually similar images | Inspiration, similar-style lookup, "more like this" |
| `about_this_image` | Contextual info about the image | Provenance, fact-check context |

### Response Structure

A Google Lens query returns these primary sections (varies by `type`):

**`visual_matches[]`** — Core match results. Each item includes:
- `position` — Rank
- `title` — Page or product title
- `link` — Source page URL
- `source` — Source site name (e.g., "amazon.com", "Wikipedia")
- `source_icon` — Favicon URL
- `thumbnail` — Small image (good for previews)
- `image` — Larger image with `width` and `height`
- `rating`, `reviews` — Product ratings when applicable
- `price` — `{ value, extracted_value, currency }` when it's a product listing
- `in_stock`, `condition` — Product availability and condition (new/used)
- `exact_matches` — Boolean flag indicating identical image match
- `serpapi_exact_matches_link` — Direct endpoint to fetch all exact matches for this item

**`related_content[]`** — Associated search queries and refinement suggestions. Useful for guiding the user toward better queries.

**`ai_overview`** — Optional AI-generated context about the image. Includes a `page_token` for fetching the full overview via the Google AI Overview engine.

**`knowledge_graph`** — Entity card when Google recognizes a known subject (landmark, public figure, product line, species). Includes name, description, attributes, and source links.

**`exact_matches[]`** (when `type=exact_matches`) — Pages where the same image appears, ranked by source authority.

### Refining with `q`

The `q` parameter narrows visual results by text. It works with `type=all`, `type=visual_matches`, and `type=products`. Useful examples:
- Image of a dress + `q="black"` → visually similar dresses in black
- Image of a chair + `q="under $200"` → matching products at that price
- Image of a plant + `q="indoor"` → indoor-suitable visual matches

### `auto_crop`

Set `auto_crop=true` to let Google focus on the main subject of the image (e.g., crop a lawnmower photo to the engine for better part matches). Useful when the image has a busy background or multiple objects.

### Localization

- `hl` — Language code (`en`, `es`, `fr`, `ja`, `de`, etc.)
- `country` — Two-letter country code (`us`, `uk`, `jp`, `de`). Localizes product results, prices, and currency.

### Google Lens vs `google_reverse_image`

Two different engines target two different surfaces:

| Engine | Backend | Strengths | Weaknesses |
|---|---|---|---|
| `google_lens` | Google Lens (modern, ML-powered) | Product ID, plants/animals, landmarks, prices, visual matches, knowledge graph | Less coverage of obscure source pages |
| `google_reverse_image` | images.google.com (classic) | Broad page-source coverage, traditional inline image results, knowledge graph for entities | No product prices, weaker on visual similarity |

**Rule of thumb:** Start with `google_lens` (`type=all` or `type=products`). Fall back to `google_reverse_image` if you specifically need page-source tracing and Lens didn't surface it.

## Workflows

### 1. Reverse Image Search to Find the Source

Find where an image originally appeared or every page that uses it.

Use the **serpapi** skill's wrapper script with the `google_lens` engine.

**Parameters:**
- `url` — Direct image URL
- `type` — `exact_matches`

**Strategy:**
1. Run with `type=exact_matches` first
2. If results are sparse, also run `type=all` and filter results where `exact_matches: true`
3. If still sparse, fall back to the `google_reverse_image` engine for broader page coverage

**Present:** Top exact-match pages sorted by source authority. Flag the earliest-known appearance if dates are present in titles or snippets.

### 2. Product Identification from a Photo

User has a photo of an item and wants to know what it is and where to buy.

**Parameters:**
- `url` — Image URL
- `type` — `products`
- `country` — Target shopping market (e.g., `us`)
- `hl` — Target language
- Optional `auto_crop=true` if the product isn't the only thing in the frame

**Present each match:**
```
🔎 [Title] — [Price] [Currency]
   [Source] · [Rating ⭐ N reviews] · [In stock / Out of stock] · [Condition]
   [Thumbnail]
   Buy: [link]
```

Sort by best match first (Lens default order), then surface the cheapest option and the highest-rated option as quick picks.

### 3. Visual Similarity Search

User wants more items, designs, or images that look like a reference image.

**Parameters:**
- `url` — Reference image
- `type` — `visual_matches`
- Optional `q` to filter (e.g., `q="leather"`, `q="vintage"`, `q="minimalist"`)

**Strategy:**
1. First pass without `q` to see what Lens picks up
2. Refine with `q` based on what the user actually wants (color, material, style, era)
3. Use `related_content` suggestions to find better refinement keywords

**Present:** Grid of 8-12 visual matches with thumbnails, source, and (if product) price.

### 4. Exact-Match Detection (Image Appears Elsewhere)

Find every page on the web where this exact image appears. Useful for:
- Copyright / leak detection
- Attribution research
- Detecting reused stock photography
- Catfish / reverse-profile detection

**Parameters:**
- `url` — Image URL
- `type` — `exact_matches`

**Tip:** Some `visual_matches` items have `exact_matches: true` and a `serpapi_exact_matches_link`. Fetch that link to expand a single match into all known copies.

### 5. Landmark and Place Identification

User has a photo of a building, monument, or place and wants to know what it is.

**Parameters:**
- `url` — Image URL
- `type` — `all`

**What to look for in the response:**
- `knowledge_graph` — Often present for famous landmarks. Includes the name, description, location, and Wikipedia/official links.
- `ai_overview` — Frequently identifies the subject with context
- `visual_matches` titles — If many results name the same landmark, that's your ID

**Present:**
```
📍 Identified: [Landmark Name]
   [Description from knowledge_graph]
   Location: [City, Country]
   Learn more: [Wikipedia / official link]
   Visual matches: [N] similar photos
```

### 6. Plant, Animal, or Insect ID

Identify a species from a photo (flowers, leaves, birds, bugs, fish, pets).

**Parameters:**
- `url` — Image URL
- `type` — `all`
- Optional `auto_crop=true` to focus on the subject

**Strategy:**
1. Run with `type=all` — Lens is very good at species ID and usually returns a `knowledge_graph` entry with scientific name
2. Cross-check by reading the top 3-5 `visual_matches` titles — they should consistently name the same species
3. If matches disagree, surface the top candidates as possibilities rather than a definitive ID

**Present:**
```
🌿 Likely identification: [Common Name] (*[Scientific Name]*)
   [Brief description / care notes from knowledge_graph]
   Confidence: [High if matches agree / Medium if mixed]
   Other possibilities: [List if visual_matches disagree]
```

### 7. Fashion and Outfit Lookup

User has a photo of clothing, shoes, a bag, or an accessory and wants to find it (or things like it) for sale.

**Parameters:**
- `url` — Image URL
- `type` — `products`
- Optional `q` for refinement: `"red"`, `"size 10"`, `"budget"`, `"luxury"`
- `country` — Shopping market
- `auto_crop=true` — Strongly recommended for outfit photos where the item is one part of a larger image

**Strategy:**
1. If the image shows a full outfit, run once for each piece with `auto_crop` (you may need to crop separately and re-host each crop)
2. First pass: `type=products` to find exact or near-exact retail matches
3. Second pass: `type=visual_matches` with `q="similar"` for cheaper alternatives or dupes

**Present:** Side-by-side of the exact match (if any) and 3-5 similar alternatives at varied price points.

### 8. Comparing Google Lens vs Traditional Reverse Image Search

When a single engine isn't producing what the user needs, run both:

**Strategy:**
1. Run `google_lens` with `type=all`
2. Run `google_reverse_image` with the same `image_url`
3. Merge results, dedupe by `link` domain
4. Note which engine surfaced each result

**When each wins:**
- `google_lens` finds → products, prices, species, landmarks, modern visual matches
- `google_reverse_image` finds → blog posts, news articles, forum threads, older indexed pages

**Present a merged view:**
```
🔎 Combined Results for [image]

From Google Lens:
   • [N] product matches with prices
   • Knowledge graph: [entity if present]
   • [N] visual matches

From Google Reverse Image:
   • [N] page sources
   • Inline image results: [N]
   • Knowledge graph: [entity if present]
```

### 9. Refining with `related_content`

Lens responses include `related_content` — suggested follow-up searches. Use these to guide the next query.

**Strategy:**
1. After any Lens search, scan `related_content` for relevant refinement terms
2. Surface 3-5 of these to the user as "Refine your search" options
3. Pass the chosen term as `q` in the next call

## Common Patterns

### "What is this thing in my photo?"
1. `type=all`, `auto_crop=true`
2. Check `knowledge_graph` and `ai_overview` first — they often answer outright
3. Fall back to summarizing the top 3 `visual_matches` titles

### "Where can I buy this?"
1. `type=products`, `country=<user's market>`
2. Sort and present by best match + cheapest + highest-rated
3. Include direct buy links and prices in matching currency

### "Find the original source of this image"
1. `type=exact_matches`
2. If sparse, also run `google_reverse_image`
3. Rank results by source authority and date if available

### "Find similar but cheaper alternatives"
1. `type=visual_matches` + `q="affordable"` or `q="dupe"`
2. Filter results with a `price` field
3. Sort ascending by `price.extracted_value`

### "Identify this plant / bird / bug"
1. `type=all`, `auto_crop=true`
2. Pull `knowledge_graph` scientific name + common name
3. Cross-verify against top `visual_matches` titles for confidence

### "Is this landmark famous?"
1. `type=all`
2. If `knowledge_graph` is present and has a Wikipedia link → yes, identify it
3. If absent but `visual_matches` consistently name the same place → likely identified
4. If matches diverge → not famous / unidentified

### "Reverse-search a profile photo"
1. `type=exact_matches` to find every page using the image
2. Run `google_reverse_image` as well for older page coverage
3. Present sources with dates; flag if image appears on unrelated identities

## Presentation Patterns

### Visual Match Card
```
[thumbnail]  [Title]
             [Source · favicon]  ⭐ [rating] ([reviews] reviews)
             [💲 Price Currency]  ·  [In stock / Out of stock]  ·  [Condition]
             → [link]
```

### Knowledge Graph Block
```
📚 [Entity Name]
   [Description]
   [Key attributes: type, location, scientific name, etc.]
   Sources: [Wikipedia link] · [Official link]
```

### Product Match Summary
```
🛒 Product Matches for [image]

Best match:
   [Title] — [Price]  ·  [Source]

Cheapest:
   [Title] — [Price]  ·  [Source]

Highest-rated:
   [Title] — ⭐ [rating] ([reviews])  ·  [Price]  ·  [Source]

[N] more matches available.
```

## Tips

- **Image URL must be public.** Lens fetches the image itself — local files, signed S3 URLs that expire, and authenticated URLs all fail. Re-host on Imgur or a public bucket if needed.
- **`type` is required.** There is no default. Pick the right one for the question — `all` is the safe first pass when unsure.
- **`auto_crop=true` is underrated.** It dramatically improves results for cluttered photos. Always enable it for product, outfit, and species ID workflows.
- **Refine with `q`, not by re-running.** Adding a text query is cheaper and more accurate than uploading a cropped image.
- **`exact_matches: true` inside `visual_matches`.** Don't ignore this flag in mixed results — it's a free signal that an item is also an exact match without needing a second call.
- **`serpapi_exact_matches_link`** is a direct API URL — fetching it expands a single result into the full list of exact matches.
- **`knowledge_graph` is the headline.** When present, lead with it — it's Google's confident answer about what the image shows.
- **`country` affects prices and currency.** Set it correctly for product searches or you'll show USD to users shopping in EUR.
- **Combine with `google_reverse_image`** for full coverage. Lens is best for *what is this*; classic reverse image is best for *where does this appear*.
- **AI overview has its own page token.** To expand `ai_overview`, fetch the Google AI Overview engine with the included `page_token` — don't try to expand it via Lens.
- **No pagination on Lens.** Unlike Google Search, Lens doesn't paginate via `start`. To get more results, switch `type` or refine with `q`.
- **Watch for stale CDN URLs.** If the same image URL keeps returning no results, try `no_cache=true` once to force a fresh fetch.
