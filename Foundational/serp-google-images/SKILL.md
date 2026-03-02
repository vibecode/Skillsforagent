---
name: serp-google-images
description: >
  Foundational skill for SerpApi Google Images API — search, filter, and retrieve image
  results from Google Images. Use when: (1) searching for images on Google programmatically,
  (2) filtering images by size, color, type, aspect ratio, license, or file format,
  (3) getting image thumbnails, original URLs, and source metadata, (4) browsing suggested
  searches (chips) or related searches from Google Images, (5) extracting shopping results
  that appear alongside image results, (6) fetching related content for a specific image,
  (7) paginating through hundreds of image results, (8) filtering images by time period
  or date range, (9) using Google Images Light API for faster response times. This is the
  base SerpApi Google Images skill — specialized skills may reference it for image research,
  visual content discovery, or stock photo workflows.
metadata: {"openclaw": {"emoji": "🖼️", "requires": {"env": ["SERPAPI_KEY"]}, "primaryEnv": "SERPAPI_KEY"}}
---

# SerpApi Google Images

Search and retrieve image results from Google Images via SerpApi's structured JSON API. Three engines cover all Google Images data needs.

## Setup

Requires `SERPAPI_KEY` environment variable. All requests go to `https://serpapi.com/search` as GET requests with `api_key` parameter.

## Engines Overview

| Engine | Purpose | Key Parameter |
|--------|---------|---------------|
| `google_images` | Search Google Images (full results) | `q` (query) |
| `google_images_light` | Search Google Images (fast, leaner data) | `q` (query) |
| `google_images_related_content` | Related content for a specific image | `related_content_id` |

**When to use Light vs Full:**

| Scenario | Engine | Reason |
|----------|--------|--------|
| Need shopping results, suggested searches, or related searches | `google_images` | Only full engine returns these |
| Need fastest possible response | `google_images_light` | ~2x faster, still returns core image data |
| Bulk image collection where metadata is secondary | `google_images_light` | Cheaper and faster |
| Need `related_content_id` for image drill-down | Either engine | Both reliably return `related_content_id` |

## Quick Reference

### 1. Search Google Images

```bash
curl -s "https://serpapi.com/search?engine=google_images&q=QUERY&api_key=$SERPAPI_KEY"
```

**Required:** `q` (query — supports `inurl:`, `site:`, `intitle:`, `filetype:` operators)

**Localization:** `gl` (country code), `hl` (language code), `google_domain`, `location`, `cr`

**Returns:** `images_results[]`, `suggested_searches[]`, `shopping_results[]`, `related_searches[]`, `search_information`, `serpapi_pagination`

### 2. Fast Image Search (Light)

```bash
curl -s "https://serpapi.com/search?engine=google_images_light&q=QUERY&api_key=$SERPAPI_KEY"
```

Same parameters as full engine. Returns `images_results[]` — no shopping, suggested searches, or related searches.

### 3. Related Content for an Image

```bash
curl -s "https://serpapi.com/search?engine=google_images_related_content&related_content_id=ID&q=ORIGINAL_QUERY&api_key=$SERPAPI_KEY"
```

**Required:** `related_content_id` (from an image result's `related_content_id` field)

**Optional:** `q` (original query — recommended for best results), `hl`, `gl`

**Returns:** `related_content[]` — array of visually similar images with full metadata, product info, ratings, and descriptions.

## Image Filtering

Google Images offers extensive filtering. Use these parameters on `google_images` or `google_images_light`.

### Size (`imgsz`)

| Value | Size |
|-------|------|
| `l` | Large |
| `m` | Medium |
| `i` | Icon |
| `qsvga` | > 400×300 |
| `vga` | > 640×480 |
| `svga` | > 800×600 |
| `xga` | > 1024×768 |
| `2mp`–`70mp` | > N megapixels |

### Aspect Ratio (`imgar`)

| Value | Ratio |
|-------|-------|
| `s` | Square |
| `t` | Tall |
| `w` | Wide |
| `xw` | Panoramic |

### Color (`image_color`)

Options: `bw` (B&W), `trans` (transparent), `red`, `orange`, `yellow`, `green`, `teal`, `blue`, `purple`, `pink`, `white`, `gray`, `black`, `brown`

### Type (`image_type`)

Options: `face`, `photo`, `clipart`, `lineart`, `animated`

### License (`licenses`)

| Value | License |
|-------|---------|
| `cl` | Creative Commons |
| `ol` | Commercial & other |
| `f` | Free to use or share |
| `fc` | Free to use/share commercially |
| `fm` | Free to use/share/modify |
| `fmc` | Free to use/share/modify commercially |

### File Format (via `tbs`)

Use `tbs=ift:FORMAT`:

| Format | `tbs` value |
|--------|-------------|
| JPG | `ift:jpg` |
| PNG | `ift:png` |
| GIF | `ift:gif` |
| BMP | `ift:bmp` |
| SVG | `ift:svg` |
| WebP | `ift:webp` |
| ICO | `ift:ico` |
| RAW | `ift:craw` |

### Time Period

**Simple period (recent images):**

| Parameter | Values |
|-----------|--------|
| `period_unit` | `s` (second), `n` (minute), `h` (hour), `d` (day), `w` (week), `m` (month), `y` (year) |
| `period_value` | Integer (default: 1). E.g., `period_unit=d&period_value=7` = past 7 days |

**Date range:**

| Parameter | Format | Example |
|-----------|--------|---------|
| `start_date` | `YYYYMMDD` | `20240101` |
| `end_date` | `YYYYMMDD` | `20240331` |

Cannot combine `period_unit/period_value` with `start_date/end_date`.

### Combining Filters via `tbs`

Multiple `tbs` values can be combined with commas: `tbs=itp:photos,isz:l` (large photos).

The dedicated parameters (`imgsz`, `imgar`, `image_color`, `image_type`, `licenses`) override corresponding `tbs` components — use the dedicated parameters when possible for clarity.

## Pagination

Image results come in batches of ~100. Pagination works differently per engine:

### Full Engine (`google_images`)

Use the `ijn` parameter (page number):

- **Page 0 (default):** `ijn=0` — first ~100 images
- **Page 1:** `ijn=1` — next ~100 images
- **Page N:** `ijn=N` — up to `ijn=99` (max)

### Light Engine (`google_images_light`)

**`ijn` does NOT paginate the light engine** — it returns the same results regardless of `ijn` value. Instead, use the `start=` offset parameter:

- **First page (default):** omit `start` or `start=0` — first ~100 images
- **Second page:** `start=100` — next ~100 images
- **Page N:** `start=N*100`

**For both engines:** check `serpapi_pagination.next` for the next page URL. When it's absent, there are no more results. Using `serpapi_pagination.next` is the safest approach — it handles the correct pagination parameter automatically.

## Suggested Searches (Chips)

On page 0 (`ijn=0`), the full engine returns `suggested_searches[]` — Google's topic refinement chips (e.g., searching "coffee" returns chips like "Cup", "Wallpaper", "Cafe").

Each suggested search includes:
- `name` — the chip label
- `chips` or `uds` — filter parameter value
- `q` — sometimes a refined query to use alongside `uds`
- `serpapi_link` — ready-to-use SerpApi URL
- `thumbnail` — chip thumbnail

**To follow a chip:** pass the `chips` value as the `chips` parameter, OR use the `uds` value as the `uds` parameter (with `q` if provided). Or just use `serpapi_link`.

## Response Schema

### `images_results[]`

| Field | Type | Description |
|-------|------|-------------|
| `position` | int | Result index |
| `thumbnail` | string | Thumbnail URL (served by SerpApi) |
| `original` | string | Original full-resolution image URL |
| `original_width` | int | Original image width in pixels |
| `original_height` | int | Original image height in pixels |
| `title` | string | Image/page title |
| `link` | string | URL of the page hosting the image |
| `source` | string | Source website name |
| `source_logo` | string | Source site favicon/logo URL |
| `tag` | string | Optional tag (e.g., "Recipe", "Licensable") |
| `is_product` | bool | Whether the source page is a product page |
| `in_stock` | bool | Product stock status (when `is_product` is true) |
| `license_details_url` | string | License URL (when filtering by license) |
| `related_content_id` | string | ID for fetching related content |
| `serpapi_related_content_link` | string | Ready-to-use SerpApi link for related content |

**Note on PDF results:** When searching with `filetype:pdf`, `original` may be `x-raw-image:///...` — an internal reference to an image extracted from a PDF.

### `shopping_results[]`

Appears for product-related queries. Each item:

| Field | Type | Description |
|-------|------|-------------|
| `position` | int | Position in shopping carousel |
| `block_position` | string | Usually `top` |
| `title` | string | Product title |
| `price` | string | Price as displayed |
| `extracted_price` | float | Price as number |
| `link` | string | Product page URL |
| `source` | string | Retailer name |
| `rating` | float | Product rating |
| `reviews` | int | Review count |
| `thumbnail` | string | Product image URL |
| `extensions` | string[] | Extra info (e.g., "Free shipping") |

### `search_information`

| Field | Description |
|-------|-------------|
| `image_results_state` | Status string, e.g., "Results for exact spelling" |

## Common Patterns

### Find High-Resolution Images

```bash
# Large images only
curl -s "https://serpapi.com/search?engine=google_images&q=mountain+landscape&imgsz=l&api_key=$SERPAPI_KEY"

# Specific minimum resolution (8+ megapixels)
curl -s "https://serpapi.com/search?engine=google_images&q=mountain+landscape&imgsz=8mp&api_key=$SERPAPI_KEY"
```

### Find Transparent PNGs

```bash
curl -s "https://serpapi.com/search?engine=google_images&q=company+logo&image_color=trans&tbs=ift:png&api_key=$SERPAPI_KEY"
```

### Find Creative Commons Licensed Images

```bash
curl -s "https://serpapi.com/search?engine=google_images&q=nature+photography&licenses=cl&api_key=$SERPAPI_KEY"
```

Results include `license_details_url` linking to the specific CC license.

### Collect All Images for a Query (Multi-Page)

**Full engine (`google_images`):**
1. Start with `ijn=0`, collect `images_results[]`
2. Check `serpapi_pagination.next` — if present, increment `ijn`
3. Repeat until no `next` or you have enough results
4. Each page returns ~100 images; max 100 pages = ~10,000 images

**Light engine (`google_images_light`):**
1. Start without `start` parameter, collect `images_results[]`
2. Check `serpapi_pagination.next` — if present, use it (or increment `start` by 100)
3. Repeat until no `next` or you have enough results
4. **Do NOT use `ijn`** — it has no effect on the light engine

### Drill Into a Specific Image

1. From any image in `images_results[]`, grab `related_content_id`
2. Call `engine=google_images_related_content` with that ID
3. Get visually similar images, product details, ratings, descriptions

### Filter by Time (Recent Images Only)

```bash
# Images from the past 24 hours
curl -s "https://serpapi.com/search?engine=google_images&q=breaking+news&period_unit=d&period_value=1&api_key=$SERPAPI_KEY"

# Images from a specific date range
curl -s "https://serpapi.com/search?engine=google_images&q=event+name&start_date=20250101&end_date=20250131&api_key=$SERPAPI_KEY"
```

## Error Handling

- Check `search_metadata.status` — should be `"Success"`
- On error, `error` field contains the message
- Cache is 1h; use `no_cache=true` to force fresh results (costs a search credit)
- Don't combine `no_cache` and `async`
- Rate limits depend on your SerpApi plan
- `search_information.image_results_state` may indicate spelling corrections or empty results

## Detailed Reference

For complete parameter tables, all response fields, and additional examples: read [references/api-reference.md](references/api-reference.md).
