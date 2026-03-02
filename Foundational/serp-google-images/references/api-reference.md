# SerpApi Google Images — API Reference

Complete parameter and response documentation for all three Google Images engines.

## Table of Contents

1. [Google Images Engine (`google_images`)](#google-images-engine)
2. [Google Images Light Engine (`google_images_light`)](#google-images-light-engine)
3. [Google Images Related Content Engine (`google_images_related_content`)](#google-images-related-content-engine)
4. [Complete Response Schemas](#complete-response-schemas)
5. [Advanced tbs Parameter](#advanced-tbs-parameter)

---

## Google Images Engine

**Endpoint:** `GET https://serpapi.com/search?engine=google_images`

### Parameters

#### Required

| Parameter | Description |
|-----------|-------------|
| `engine` | Must be `google_images` |
| `q` | Search query. Supports operators: `inurl:`, `site:`, `intitle:`, `filetype:` |
| `api_key` | SerpApi API key |

#### Geographic Location

| Parameter | Description |
|-----------|-------------|
| `location` | City-level location string (e.g., "Austin, TX"). Cannot combine with `uule` |
| `uule` | Google-encoded location. Cannot combine with `location` |

#### Localization

| Parameter | Default | Description |
|-----------|---------|-------------|
| `google_domain` | `google.com` | Google domain (e.g., `google.co.uk`, `google.de`) |
| `gl` | — | Country code (e.g., `us`, `uk`, `fr`) |
| `hl` | — | Language code (e.g., `en`, `es`, `fr`) |
| `cr` | — | Country restrict. Format: `countryXX\|countryYY` (e.g., `countryFR\|countryDE`) |

#### Time Period (Simple)

| Parameter | Description |
|-----------|-------------|
| `period_unit` | Unit: `s` (second), `n` (minute), `h` (hour), `d` (day), `w` (week), `m` (month), `y` (year) |
| `period_value` | Integer value (default: 1). Range: 1–2147483647 |

Cannot combine with `start_date`/`end_date`. Overrides `qdr` component of `tbs`.

#### Time Period (Date Range)

| Parameter | Format | Description |
|-----------|--------|-------------|
| `start_date` | `YYYYMMDD` | Start of date range. With blank `end_date`: FROM start TO today |
| `end_date` | `YYYYMMDD` | End of date range. With blank `start_date`: BEFORE end_date |

Cannot combine with `period_unit`/`period_value`. Overrides `cdr`, `cd_min`, `cd_max` of `tbs`.

#### Image Filters

| Parameter | Values | Description |
|-----------|--------|-------------|
| `imgsz` | `l`, `m`, `i`, `qsvga`, `vga`, `svga`, `xga`, `2mp`–`70mp` | Image size filter |
| `imgar` | `s` (square), `t` (tall), `w` (wide), `xw` (panoramic) | Aspect ratio |
| `image_color` | `bw`, `trans`, `red`, `orange`, `yellow`, `green`, `teal`, `blue`, `purple`, `pink`, `white`, `gray`, `black`, `brown` | Color filter |
| `image_type` | `face`, `photo`, `clipart`, `lineart`, `animated` | Image type filter |
| `licenses` | `f`, `fc`, `fm`, `fmc`, `cl`, `ol` | License scope |
| `chips` | String from `suggested_searches[].chips` | Topic refinement chip filter |
| `tbs` | Encoded string | Advanced filters (see section below) |

#### Pagination

| Parameter | Default | Description |
|-----------|---------|-------------|
| `ijn` | `0` | Page number. Range: 0–99. Each page returns ~100 images |

#### Other

| Parameter | Default | Description |
|-----------|---------|-------------|
| `safe` | — | Safe search: `active` or `off` |
| `nfpr` | `0` | Exclude auto-corrected results: `1` to exclude |
| `filter` | `1` | Similar/omitted result filters: `0` to disable |
| `device` | `desktop` | Device type: `desktop`, `tablet`, `mobile` |
| `no_cache` | `false` | Force fresh results (costs a credit). Don't combine with `async` |
| `async` | `false` | Submit and retrieve later. Don't combine with `no_cache` |
| `output` | `json` | Output format: `json` or `html` |
| `json_restrictor` | — | Restrict output fields for smaller responses |

---

## Google Images Light Engine

**Endpoint:** `GET https://serpapi.com/search?engine=google_images_light`

Accepts the same parameters as the full `google_images` engine with one critical pagination difference:

**Pagination:** The `ijn` parameter does **not** work on the light engine — it returns identical results regardless of `ijn` value. Use `serpapi_pagination.next` to get the next page URL, which includes the correct `start=` offset automatically.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `start` | `0` | Result offset. **Do not hardcode offset increments** — the step size varies. Always follow `serpapi_pagination.next` for reliable pagination. |

Alternatively, follow the `serpapi_pagination.next` URL which uses the correct pagination parameter automatically.

**Key differences from full engine:**
- ~2x faster response times
- Uses `start=` offset pagination instead of `ijn` page numbers
- Returns `images_results[]` only
- Does **not** return `shopping_results[]`, `suggested_searches[]`, or `related_searches[]`
- Ideal for bulk image collection or when speed matters more than rich metadata

---

## Google Images Related Content Engine

**Endpoint:** `GET https://serpapi.com/search?engine=google_images_related_content`

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `engine` | Yes | Must be `google_images_related_content` |
| `related_content_id` | Yes | ID from `images_results[].related_content_id` |
| `api_key` | Yes | SerpApi API key |
| `q` | No | Original query (recommended for better results) |
| `hl` | No | Language code |
| `gl` | No | Country code |
| `no_cache` | No | Force fresh results |
| `async` | No | Async mode |
| `output` | No | `json` or `html` |

**Note:** This engine does not have standard HTML output. Use `search_metadata.prettify_html_file` for debugging.

---

## Complete Response Schemas

### Google Images Response

```json
{
  "search_metadata": {
    "id": "string — Search ID",
    "status": "string — 'Success' or 'Error'",
    "json_endpoint": "string — URL to JSON results",
    "created_at": "string — Timestamp",
    "processed_at": "string — Timestamp",
    "google_images_url": "string — Google URL used",
    "raw_html_file": "string — URL to raw HTML",
    "total_time_taken": "float — Seconds"
  },
  "search_parameters": {
    "engine": "google_images",
    "q": "string — Query",
    "...": "other params echoed back"
  },
  "search_information": {
    "image_results_state": "string — e.g., 'Results for exact spelling'"
  },
  "suggested_searches": [],
  "images_results": [],
  "shopping_results": [],
  "related_searches": [],
  "serpapi_pagination": {}
}
```

### `images_results[]` — Full Schema

| Field | Type | Always Present | Description |
|-------|------|----------------|-------------|
| `position` | int | Yes | 1-based index |
| `thumbnail` | string | Yes | Thumbnail URL (SerpApi-hosted) |
| `original` | string | Yes | Full-resolution image URL |
| `original_width` | int | Yes | Width in pixels |
| `original_height` | int | Yes | Height in pixels |
| `title` | string | Yes | Page/image title |
| `link` | string | Yes | Source page URL |
| `source` | string | Yes | Source website name |
| `source_logo` | string | No | Source favicon/logo |
| `tag` | string | No | Tag like "Recipe", "Licensable", "Product" |
| `is_product` | bool | Yes | Whether source page has a product |
| `in_stock` | bool | No | Stock status (when `is_product` is true) |
| `license_details_url` | string | No | CC license URL (when license filter active) |
| `related_content_id` | string | No | ID for drilling into related content |
| `serpapi_related_content_link` | string | No | Ready-to-use SerpApi link |

**PDF image results:** When results come from PDF files (e.g., `filetype:pdf`), the `original` field may contain `x-raw-image:///HASH` — a reference to an image extracted from within the PDF document. These cannot be used as direct image URLs.

### `suggested_searches[]` — Full Schema

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Chip display name |
| `link` | string | Google search URL |
| `chips` | string | Value for `chips` parameter (older format) |
| `uds` | string | Value for `uds` parameter (newer format) |
| `q` | string | Refined query to use alongside `uds` |
| `serpapi_link` | string | Ready-to-use SerpApi URL |
| `thumbnail` | string | Chip thumbnail image |

**Using suggested searches:** Either pass `chips` as the `chips` parameter, or pass `uds` as the `uds` parameter (with `q` if provided in the suggestion). The `serpapi_link` handles this automatically.

### `shopping_results[]` — Full Schema

| Field | Type | Description |
|-------|------|-------------|
| `position` | int | Position in carousel |
| `block_position` | string | Usually `"top"` |
| `title` | string | Product title |
| `price` | string | Display price |
| `extracted_price` | float | Price as number |
| `link` | string | Product page URL |
| `source` | string | Retailer name |
| `rating` | float | Product rating (optional) |
| `reviews` | int | Review count (optional) |
| `reviews_original` | string | Reviews in text format (optional) |
| `thumbnail` | string | Product image URL |
| `extensions` | string[] | Extra info like "Free shipping" |

### `related_searches[]` — Full Schema

| Field | Type | Description |
|-------|------|-------------|
| `query` | string | Related search query text |
| `link` | string | Google Images search URL |
| `serpapi_link` | string | SerpApi URL for this search |
| `highlighted_words` | string[] | Words highlighted in the query |
| `thumbnail` | string | Thumbnail image for the search |

### `serpapi_pagination` — Full Schema

| Field | Type | Description |
|-------|------|-------------|
| `current` | int | Current page index (0-based) |
| `next` | string | SerpApi URL for next page (absent when no more results) |
| `previous` | string | SerpApi URL for previous page (absent on page 0) |

### Related Content Response (`related_content[]`)

| Field | Type | Always Present | Description |
|-------|------|----------------|-------------|
| `position` | int | Yes | 1-based index |
| `title` | string | Yes | Page title |
| `source` | string | Yes | Source website name |
| `source_icon` | string | No | Source favicon |
| `link` | string | Yes | Source page URL |
| `original` | string | Yes | Full-resolution image URL |
| `original_width` | int | Yes | Width in pixels |
| `original_height` | int | Yes | Height in pixels |
| `thumbnail` | string | Yes | Thumbnail URL |
| `thumbnail_width` | int | No | Thumbnail width |
| `thumbnail_height` | int | No | Thumbnail height |
| `is_product` | bool | No | Whether it's a product page |
| `rating` | float | No | Product rating |
| `reviews` | int | No | Review count |
| `description` | string | No | Product/page description |
| `in_stock` | bool | No | Stock status |
| `related_content_id` | string | No | ID for further drill-down |
| `serpapi_related_content_link` | string | No | SerpApi link for next level |

---

## Advanced tbs Parameter

The `tbs` parameter encodes advanced filters. Multiple values are comma-separated.

### Image Size (`isz`)

| `tbs` value | Description |
|-------------|-------------|
| `isz:l` | Large |
| `isz:m` | Medium |
| `isz:i` | Icon |
| `isz:lt,islt:qsvga` | Larger than 400×300 |
| `isz:lt,islt:vga` | Larger than 640×480 |
| `isz:lt,islt:svga` | Larger than 800×600 |
| `isz:lt,islt:xga` | Larger than 1024×768 |
| `isz:lt,islt:2mp` | Larger than 2 MP |
| `isz:ex,iszw:WIDTH,iszh:HEIGHT` | Exact size |

**Note:** Prefer the `imgsz` parameter over `tbs` for size filtering — it's cleaner. Use `tbs` only for exact-size filtering.

### Image Type (`itp`)

| `tbs` value | Description |
|-------------|-------------|
| `itp:photo` | Photos |
| `itp:face` | Faces |
| `itp:clipart` | Clip art |
| `itp:lineart` | Line drawings |
| `itp:animated` | Animated/GIF |

### Color (`ic` / `isc`)

| `tbs` value | Description |
|-------------|-------------|
| `ic:gray` | Black and white |
| `ic:trans` | Transparent |
| `ic:specific,isc:red` | Specific color (red, orange, yellow, green, teal, blue, purple, pink, white, gray, black, brown) |

### File Format (`ift`)

| `tbs` value | Description |
|-------------|-------------|
| `ift:jpg` | JPEG |
| `ift:png` | PNG |
| `ift:gif` | GIF |
| `ift:bmp` | BMP |
| `ift:svg` | SVG |
| `ift:webp` | WebP |
| `ift:ico` | ICO |
| `ift:craw` | RAW |

### License (`sur`)

| `tbs` value | Description |
|-------------|-------------|
| `sur:cl` | Creative Commons licenses |
| `sur:ol` | Commercial & other licenses |
| `sur:f` | Free to use or share |
| `sur:fc` | Free to use/share commercially |
| `sur:fm` | Free to use/share/modify |
| `sur:fmc` | Free to use/share/modify commercially |

### Time (`qdr`)

| `tbs` value | Description |
|-------------|-------------|
| `qdr:s` | Past second |
| `qdr:n` | Past minute |
| `qdr:h` | Past hour |
| `qdr:d` | Past day |
| `qdr:w` | Past week |
| `qdr:m` | Past month |
| `qdr:y` | Past year |
| `qdr:s15` | Past 15 seconds |
| `qdr:h6` | Past 6 hours |
| `qdr:d3` | Past 3 days |

### Date Range (`cdr`)

| `tbs` value | Description |
|-------------|-------------|
| `cdr:1,cd_min:MM/DD/YYYY,cd_max:MM/DD/YYYY` | Custom date range |

**Note:** Prefer the `start_date`/`end_date` parameters over `tbs` for date range filtering.

### Combining tbs Values

Comma-separate multiple filters:

```
tbs=itp:photo,isz:l,ift:jpg,sur:cl
```

This searches for: large, JPEG, Creative Commons photos.

### Priority of Dedicated Parameters vs tbs

The dedicated parameters (`imgsz`, `imgar`, `image_color`, `image_type`, `licenses`, `period_unit`, `start_date`, `end_date`) override their corresponding `tbs` components:

| Dedicated Parameter | Overrides `tbs` Component |
|---------------------|---------------------------|
| `imgsz` | `isz` |
| `imgar` | `iar` (deprecated) |
| `image_color` | `ic`, `isc` |
| `image_type` | `itp` |
| `licenses` | `sur` |
| `period_unit`/`period_value` | `qdr` |
| `start_date`/`end_date` | `cdr`, `cd_min`, `cd_max` |
