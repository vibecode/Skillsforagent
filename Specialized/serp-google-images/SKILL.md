---
name: serp-google-images
description: >
  Specialized skill for Google Images search workflows via SerpApi — find images by topic,
  filter by size/color/type/license, reverse image search, explore related content, and
  curate visual collections. Use when: (1) searching for images on a topic or keyword,
  (2) finding high-resolution or specific-size images, (3) filtering images by color,
  type (photo, clipart, line art, animated), or license (Creative Commons, commercial),
  (4) performing reverse image search to find where an image appears online,
  (5) finding visually similar or related images, (6) curating a collection of images
  for a project, presentation, or mood board, (7) sourcing stock-style or reference images
  with specific dimensions or aspect ratios, (8) time-filtered image search for recent
  images only, (9) any image discovery or visual research task via Google Images.
  This skill builds on the foundational serpapi skill for all API details.
metadata: {"openclaw": {"emoji": "🖼️", "requires": {"env": ["SERPAPI_KEY"]}, "primaryEnv": "SERPAPI_KEY"}}
---

# Google Images Search Workflows

Image search, filtering, reverse lookup, related content discovery, and visual curation via SerpApi's Google Images engines. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engines: `google_images`, `google_images_light`, `google_images_related_content`, `google_reverse_image`)

## Engine Selection

| Engine | Purpose | Speed | Best For |
|--------|---------|-------|----------|
| `google_images` | Full image search | Normal | Detailed results with shopping, suggested searches |
| `google_images_light` | Lightweight image search | Faster | Quick searches, bulk queries, when you don't need shopping/suggestions |
| `google_images_related_content` | Related images for a specific result | Normal | "More like this" exploration |
| `google_reverse_image` | Reverse image search by URL | Normal | Finding image sources, visual matches, identification |

**Default to `google_images`** for most workflows. Use `google_images_light` when speed matters or you're doing many searches in sequence.

## Response Structure

### Image Results

Each item in `images_results[]` includes:
- `position` — Result index
- `title` — Image description/caption
- `original` — Full-resolution image URL
- `original_width` / `original_height` — Image dimensions in pixels
- `thumbnail` — Smaller preview URL
- `source` — Domain hosting the image
- `link` — Page URL where the image appears
- `is_product` — Whether the image links to a product page
- `in_stock` — Product availability (when `is_product` is true)
- `related_content_id` — ID for fetching related/similar images
- `tag` — Optional label (e.g., "Recipe", "Product")

### Additional Response Sections

- `suggested_searches[]` — Refinement suggestions with `name`, `chips`, `thumbnail`
- `shopping_results[]` — Product results with `title`, `price`, `source`, `link`, `thumbnail`
- `related_searches[]` — Related query suggestions with `query`, `thumbnail`

### Pagination

Images return in batches of ~100. Paginate with the `ijn` parameter:
- `ijn=0` — First page (default)
- `ijn=1` — Second page (results 101-200)
- `ijn=2` — Third page (results 201-300)

For `google_images_light`, use the `start` parameter instead (offset-based, 0-999).

## Workflows

### 1. Basic Image Search

Search for images on any topic using the `google_images` engine.

**Required:** `q` (search query)
**Recommended:** Size and type filters when the user has specific needs

**What to present:** 5-10 results with title, source, dimensions, and original URL. Include thumbnails descriptions when helpful.

**Query tips:**
- Be specific: "golden retriever puppy outdoors" beats "dog"
- Use quotes for exact phrases: `"modern kitchen design"`
- Add context: "logo transparent background" or "infographic template"

### 2. Filtered Image Search

Apply filters to narrow results. All filters go through the `google_images` or `google_images_light` engine as parameters.

#### Size Filters

| Need | Parameter Value | Notes |
|------|----------------|-------|
| Large images | `imgsz=l` | Good default for high-quality results |
| Medium images | `imgsz=m` | Balanced size/speed |
| Icons/thumbnails | `imgsz=i` | Small images only |
| Minimum resolution | `imgsz=2mp`, `4mp`, `8mp`, etc. | Specific megapixel minimum (up to 70mp) |
| Specific minimum | `imgsz=qsvga` (400×300), `vga` (640×480), `svga` (800×600), `xga` (1024×768) | Named size thresholds |

#### Aspect Ratio Filters

| Ratio | Parameter Value |
|-------|----------------|
| Square | `imgar=s` |
| Tall (portrait) | `imgar=t` |
| Wide (landscape) | `imgar=w` |
| Panoramic (ultra-wide) | `imgar=xw` |

#### Color Filters

| Need | Parameter Value |
|------|----------------|
| Black and white | `image_color=bw` |
| Transparent background | `image_color=trans` |
| Specific color dominant | `image_color=red`, `orange`, `yellow`, `green`, `teal`, `blue`, `purple`, `pink`, `white`, `gray`, `black`, `brown` |

#### Type Filters

| Type | Parameter Value |
|------|----------------|
| Photos only | `image_type=photo` (or `imgtype=photo`) |
| Clip art | `image_type=clipart` |
| Line drawings | `image_type=lineart` |
| Animated/GIF | `image_type=animated` |
| Face-focused | `image_type=face` |

#### License Filters

| License | Parameter Value | Use Case |
|---------|----------------|----------|
| Creative Commons | `licenses=cl` | Free to use with attribution |
| Commercial use | `licenses=ol` | Safe for business use |
| Free to share | `licenses=f` | Personal sharing OK |
| Free commercial share | `licenses=fc` | Commercial sharing OK |
| Free to modify | `licenses=fm` | Can edit/remix |
| Free commercial modify | `licenses=fmc` | Can edit/remix commercially |

**Combining filters:** Pass multiple filter parameters in the same request. They stack — e.g., large + transparent + photo narrows results to large transparent photos.

### 3. Time-Filtered Search

Find images from a specific time period.

**Option A — Relative time:**
- `period_unit` + `period_value` — e.g., `period_unit=d`, `period_value=7` for past week
- Units: `s` (second), `n` (minute), `h` (hour), `d` (day), `w` (week), `m` (month), `y` (year)

**Option B — Date range:**
- `start_date` + `end_date` in `YYYYMMDD` format
- `start_date` alone = from that date to today
- `end_date` alone = before that date

**Use cases:**
- Recent product photos: `period_unit=m`, `period_value=3`
- Event coverage: date range around the event dates
- Trending visuals: `period_unit=w`, `period_value=1`

### 4. Reverse Image Search

Find where an image appears online, identify objects, or find similar images using the `google_reverse_image` engine.

**Required:** `image_url` — a publicly accessible URL of the image to search

**Optional:** `q` — add a text query alongside the image for more targeted results

**What you get:**
- `image_results[]` — Pages containing the same or similar image
- `inline_images[]` — Visually similar images
- `knowledge_graph` — Identified subject (if recognizable)

**Use cases:**
- **Source finding:** "Where did this image originate?" — Check the oldest/most authoritative results
- **Fact checking:** Verify if an image is being used in context or is misleading
- **Identification:** "What is this object/landmark/plant?" — Check knowledge graph
- **Higher resolution:** Find the same image at better quality from different sources
- **Copyright check:** See where an image is used across the web

**Presentation pattern:**
1. If knowledge graph identifies the subject, lead with that
2. List top sources where the image appears (domain, page title)
3. Show visually similar images if the user wants alternatives

### 5. Related Content Exploration

When a user likes a specific image and wants more like it, use the `google_images_related_content` engine.

**Required:** `related_content_id` — from an image result's `related_content_id` field

**Workflow:**
1. Perform initial image search
2. User identifies an image they like (by position or description)
3. Use that image's `related_content_id` to fetch related content
4. Present the visually similar results

This is Google's "more like this" feature — it finds images with similar visual characteristics, subject matter, and style.

### 6. Visual Curation / Mood Board

When a user wants to collect images for a project, presentation, or creative brief:

**Step 1: Broad search** — Start with a general query to understand what's available.

**Step 2: Refine with filters** — Apply size, color, type, and aspect ratio filters based on the user's project needs.

**Step 3: Explore related content** — For images the user likes, use related content to find similar ones.

**Step 4: Compile results** — Present a curated selection organized by theme or style.

**Presentation format:**

```
🖼️ Image Collection: [Theme]

1. "[Title]" — [Source]
   📐 [Width]×[Height] | 🔗 [original URL]
   
2. "[Title]" — [Source]
   📐 [Width]×[Height] | 🔗 [original URL]

...

💡 Suggested refinements: [from suggested_searches]
```

**Tips:**
- Use `imgsz=l` or specific megapixel minimums for print/high-quality projects
- Use `image_color=trans` for images that need to overlay other content
- Use `imgar=w` for banner/header images, `imgar=s` for social media posts
- Filter by license when images will be used commercially

### 7. Product Image Search

When looking for product images, shopping results are especially useful:

**Strategy:**
1. Search with product-specific query (brand + product name)
2. Check `shopping_results[]` for product images with prices and availability
3. Check `images_results[]` where `is_product=true` for additional product images
4. Filter `in_stock=true` results if linking to purchasable items matters

**Presentation pattern:**

```
🛒 Product Images: [Product]

Shopping Results:
• [Title] — $[Price] from [Source]
  🔗 [link]

Image Results (product pages):
• "[Title]" — [Source] | 📐 [dimensions]
  🔗 [original URL]
```

### 8. Reference Image Search

When searching for images as reference material (design, art, architecture, etc.):

**Strategy:**
1. Use descriptive, style-specific queries: "brutalist architecture exterior", "watercolor landscape tutorial", "80s retro neon aesthetic"
2. Filter to large images (`imgsz=l` or `imgsz=4mp`+) for detail
3. Use color filters to match a palette: `image_color=teal` for cool tones
4. Use type filters: `image_type=photo` for realism, `image_type=lineart` for technical references
5. Explore suggested searches for related style terms
6. Use related content to branch out from strong matches

### 9. Iterative Refinement

When initial results don't match what the user needs:

**Refine the query:**
- Add adjectives: "minimalist", "vintage", "high-contrast", "aerial view"
- Add context: "for website", "on white background", "editorial style"
- Exclude terms with `-`: `"modern kitchen -IKEA"`

**Add filters:**
- Too many small images → add `imgsz=l`
- Wrong style → add `image_type=photo` or `image_type=clipart`
- Wrong colors → add `image_color` filter
- Wrong proportions → add `imgar` filter

**Explore branches:**
- Use `suggested_searches[]` from results — these are Google's refinement suggestions
- Use `related_searches[]` for tangential topics
- Use related content for visual similarity exploration

**Paginate:**
- With `google_images`: increment `ijn` (0, 1, 2...)
- With `google_images_light`: increment `start` (0, 100, 200...)

## Presenting Results

### Standard Image Search Results

```
🖼️ Google Images: "[query]"

1. "[Title]" — [Source]
   📐 [Width]×[Height] | [tag if present]
   🔗 [original URL]

2. "[Title]" — [Source]
   📐 [Width]×[Height]
   🔗 [original URL]

...

💡 Try also: [2-3 suggested searches from results]
```

### Reverse Image Search Results

```
🔍 Reverse Image Search

🧠 Identified: [knowledge graph result, if present]

📍 Found on:
1. [Page title] — [domain]
   🔗 [link]
2. [Page title] — [domain]
   🔗 [link]

🖼️ Visually Similar:
• "[Title]" — [Source] | 📐 [dimensions]
• "[Title]" — [Source] | 📐 [dimensions]
```

## Common Patterns

### "Find images of [topic]"
1. Search with `google_images`, `q=[topic]`
2. Present top 5-8 results with titles, sources, and dimensions
3. Offer to filter by size, color, or type

### "Find large/HD images of [topic]"
1. Search with `imgsz=l` or specific megapixel minimum
2. Sort presentation by dimensions (largest first)
3. Note which images have the best resolution

### "Find images with transparent background"
1. Search with `image_color=trans`
2. Note: results are typically PNG format
3. Verify by checking file extensions in original URLs when possible

### "Find free-to-use images of [topic]"
1. Search with `licenses=cl` (Creative Commons) or `licenses=ol` (commercial)
2. Always note the license type — "free to use" doesn't mean "no attribution"
3. Recommend the user verify the license on the source page

### "Where is this image from?" / "What is this?"
1. Use `google_reverse_image` with `image_url`
2. Check knowledge graph for identification
3. List the top sources by authority/date
4. Show visually similar images if the user wants alternatives

### "Find images similar to this one"
1. First search to locate the reference image in results (or use reverse search)
2. Get the `related_content_id` from the matching result
3. Use `google_images_related_content` to fetch similar images
4. Present the related results

### "Find [topic] images from the last [time period]"
1. Search with `period_unit` and `period_value` matching the requested timeframe
2. Or use `start_date`/`end_date` for specific date ranges
3. Useful for news events, recent product launches, seasonal content

## Tips

- **Default to large images** unless the user asks otherwise — `imgsz=l` gives better quality results with minimal downside.
- **`google_images_light` for speed** — when doing multiple searches in sequence (e.g., comparing results across queries), use the light engine to save time and API credits.
- **Combine filters freely** — size + color + type + license all work together. More filters = fewer but more relevant results.
- **Suggested searches are gold** — the `suggested_searches[]` array contains Google's own refinement ideas. Use them to help users who aren't sure exactly what they want.
- **Product detection** — `is_product` and `in_stock` fields help distinguish commercial images from editorial/informational ones.
- **`tbs` for advanced users** — the `tbs` parameter accepts raw Google filter strings. If the user knows the exact filter string from a Google Images URL, pass it directly.
- **Aspect ratio for specific uses** — `imgar=w` for banners/headers, `imgar=t` for phone wallpapers/Pinterest, `imgar=s` for avatars/profile pictures, `imgar=xw` for panoramic/landscape.
- **Localization matters** — use `gl` and `hl` to get region-appropriate image results (e.g., food images vary significantly by region).
- **License disclaimer** — always remind users that license filters are based on metadata and should be verified on the source page before commercial use.
