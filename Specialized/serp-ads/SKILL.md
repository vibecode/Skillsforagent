---
name: SERP Ads
description: >
  Specialized skill for Google Ads intelligence workflows via SerpApi — competitor ad research,
  advertiser discovery, ad creative analysis, ad format tracking, political ad monitoring,
  platform-specific ad filtering, and ad timeline analysis. Use when: (1) researching a
  competitor's Google Ads campaigns or ad history, (2) finding all ads run by a specific
  advertiser or domain, (3) analyzing ad creatives (text, image, video) for messaging and
  strategy, (4) tracking when and where ads were shown (dates, regions, platforms),
  (5) monitoring political advertising by region, (6) comparing ad strategies across
  competitors, (7) finding ads on specific platforms (YouTube, Search, Shopping, Maps, Play),
  (8) investigating ad creative formats and messaging patterns, (9) any task involving
  the Google Ads Transparency Center. This skill builds on the foundational serpapi skill
  for all API details.
dependencies:
  - serpapi
metadata: {"openclaw": {"emoji": "📢", "requires": {"env": ["SERPAPI_API_KEY"]}, "primaryEnv": "SERPAPI_API_KEY"}}
---

# Google Ads Intelligence Workflows

Competitor ad research, creative analysis, timeline tracking, and political ad monitoring via SerpApi's Google Ads Transparency Center engines. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engines: `google_ads_transparency_center`, `google_ads_transparency_center_ad_details`)

## Core Concepts

### Engines

| Engine | Purpose | Key Inputs |
|--------|---------|------------|
| `google_ads_transparency_center` | List ads by advertiser or domain | `advertiser_id` or `text` (domain/name) |
| `google_ads_transparency_center_ad_details` | Detailed info for a specific ad creative | `advertiser_id` + `creative_id` |

### Finding Advertisers

Advertisers are identified by:
- **Advertiser ID** — format `AR` + digits (e.g., `AR17828074650563772417` for Tesla Inc.)
- **Domain search** — pass the domain as the `text` parameter (e.g., `text=apple.com`)

The `text` parameter is the easiest way to discover an advertiser — use whatever you'd type into the Google Ads Transparency Center search bar (domain, brand name, etc.).

### Ad Creative Results

Each ad creative in the listing response includes:
- `advertiser_id` / `advertiser` — Advertiser info
- `ad_creative_id` — Unique ID (format `CR` + digits), used for fetching details
- `format` — `text`, `image`, or `video`
- `image` — Screenshot/preview of the ad
- `width` / `height` — Creative dimensions
- `first_shown` / `last_shown` — Unix timestamps for when the ad was active
- `details_link` — Google's transparency page for this ad
- `serpapi_details_link` — Direct SerpApi link to fetch details

### Ad Detail Results

The details endpoint returns richer data per creative:

**For text ads:**
- `title`, `headline`, `long_headline` — Ad copy elements
- `snippet` — Ad description text
- `visible_link` / `link` — Display URL and destination URL
- `sitelink_texts` / `sitelink_descriptions` — Sitelink extensions
- `advertiser_logo` / `advertiser_logo_alt` — Branding

**For image ads:**
- `image` — Full creative image URL
- `call_to_action` — CTA button text
- `snippet` — Ad text overlay
- `link` — Destination URL
- `carousel_data[]` — If carousel format: images, headlines, button links
- `images[]` — Multiple image variants with tags

**For video ads:**
- `video_link` — Video URL (often YouTube-hosted)
- `raw_video_link` — Direct video file link (when available)
- `video_duration` — Duration string
- `headline`, `call_to_action`, `snippet` — Ad copy
- `channel_name` / `channel_icon` — YouTube channel info

**Common detail fields:**
- `rating` / `reviews` / `reviews_link` — If product-related
- `address` — For local/store ads
- `is_verified` — Advertiser verification status
- `extensions[]` — Additional ad extensions

**Search information (from details):**
- `format` — Creative type
- `last_shown` — Most recent display timestamp
- `region_name` — Target region
- `ad_funded_by` — Funding entity (especially for political ads)
- `regions[]` — Full list of regions where ad ran, with `first_shown`, `last_shown`, and `times_shown`

### Pagination

The listing endpoint returns up to `num` results (default 40). Paginate with `next_page_token` from the response. Each page costs one search credit.

### Filters

| Filter | Parameter | Values |
|--------|-----------|--------|
| Platform | `platform` | `SEARCH`, `YOUTUBE`, `SHOPPING`, `MAPS`, `PLAY` |
| Format | `creative_format` | `text`, `image`, `video` |
| Region | `region` | Region code (see Google Ads Transparency regions) |
| Date range | `start_date` / `end_date` | `YYYYMMDD` format |
| Political | `political_ads` | `true` (requires `region`) |

## Workflows

### 1. Competitor Ad Research

Discover what ads a competitor is running and how they position themselves.

**Step 1: Find the advertiser.**
Use the **serpapi** skill with `google_ads_transparency_center` engine and `text` set to the competitor's domain (e.g., `text=competitor.com`).

**Step 2: Browse their ad catalog.**
Results return `ad_creatives[]` — scan `format`, `first_shown`/`last_shown` timestamps, and the ad preview `image`. Note which creatives are currently active (recent `last_shown`).

**Step 3: Analyze key creatives.**
For interesting ads, use `google_ads_transparency_center_ad_details` with the `advertiser_id` + `creative_id` to get full creative details — headlines, descriptions, CTAs, sitelinks, and destination URLs.

**What to extract:**
- **Messaging themes** — What value propositions do they lead with?
- **CTAs** — What actions do they push? (Shop now, Learn more, Get started)
- **Landing pages** — Where do ads link? (Product pages, landing pages, blog posts)
- **Sitelink strategy** — What additional links do they promote?
- **Format mix** — Ratio of text vs image vs video ads
- **Active period** — How long do they run ads? Seasonal patterns?

**Presentation:**

```
📢 Ad Intelligence: [Competitor]
Advertiser: [name] (ID: [advertiser_id])
Total ads found: [count]

🔤 Text Ads ([count]):
• "[headline]" — [snippet excerpt]
  CTA: [call_to_action] | 🔗 [visible_link]
  Active: [first_shown] → [last_shown]

🖼️ Image Ads ([count]):
• [call_to_action] — [snippet excerpt]
  📐 [width]×[height] | 🔗 [link]

🎬 Video Ads ([count]):
• "[headline]" — [video_duration]
  CTA: [call_to_action] | 🔗 [link]

💡 Key Insights:
- [Messaging patterns observed]
- [CTA preferences]
- [Landing page strategy]
```

### 2. Ad Creative Deep Dive

When the user wants detailed analysis of specific ad creatives.

**Step 1: Get the creative listing** (if not already done).
Search by advertiser ID or domain using `google_ads_transparency_center`.

**Step 2: Fetch details for target creatives.**
Use `google_ads_transparency_center_ad_details` with `advertiser_id` + `creative_id`.

**Step 3: Analyze the creative.**

For **text ads**, focus on:
- Headline progression (title → headline → long_headline)
- Description/snippet copywriting
- Sitelink strategy and what pages they promote
- URL structure (vanity URLs, UTM patterns)

For **image ads**, focus on:
- Visual style and branding consistency
- CTA placement and text
- If carousel: how many cards, what progression/story
- Image dimensions and aspect ratios (indicates platform targeting)

For **video ads**, focus on:
- Video duration (6s bumper, 15s, 30s, long-form)
- Channel association (branded YouTube channel?)
- CTA overlay text
- Whether it's a repurposed organic video or ad-specific

### 3. Platform-Specific Analysis

Understand how an advertiser targets different Google platforms.

**Strategy:** Run the listing search multiple times with different `platform` filters:
- `SEARCH` — Google Search text ads
- `YOUTUBE` — Video ads and display on YouTube
- `SHOPPING` — Product listing ads
- `MAPS` — Local/map ads
- `PLAY` — App install ads

**What to compare:**
- Which platforms they invest in most (ad count per platform)
- How messaging differs across platforms
- Format preferences per platform (text on Search, video on YouTube)
- Whether they use platform-specific features (Shopping product feeds, Maps local info)

**Presentation:**

```
📊 Platform Breakdown: [Advertiser]

🔍 Google Search: [count] ads
   Formats: [text: X, image: Y]
   Top themes: [themes]

▶️ YouTube: [count] ads
   Formats: [video: X, image: Y]
   Avg duration: [duration]

🛒 Shopping: [count] ads
🗺️ Maps: [count] ads
📱 Play: [count] ads

💡 Platform strategy: [summary]
```

### 4. Ad Timeline Analysis

Track how an advertiser's ad strategy evolves over time.

**Step 1: Get the full ad listing** for the advertiser.

**Step 2: Analyze timestamps.**
Each creative has `first_shown` and `last_shown` (Unix timestamps). Convert to dates and map out:
- Currently active ads (recent `last_shown`)
- Campaign duration patterns (how long each ad runs)
- Launch clusters (multiple ads starting around the same date = new campaign)
- Seasonal patterns (holiday campaigns, product launches)

**Step 3: For deeper timeline data**, fetch details on key creatives.
The detail response includes `regions[]` with per-region `first_shown`/`last_shown`/`times_shown` — showing geographic rollout patterns.

**Step 4: Use date-range filters** to focus on specific periods.
Pass `start_date` and `end_date` (YYYYMMDD) to narrow results to a time window. For today's ads only, set `end_date` = `start_date` + 1 day.

**What to look for:**
- Campaign cycles — How often do they refresh creatives?
- Geographic expansion — Did they start in one region and expand?
- Seasonal spikes — More ads during holidays, events, or product launches?
- Format evolution — Shifting from text to video over time?

### 5. Competitor Comparison

Compare ad strategies across multiple competitors.

**Step 1: List competitors** (2-5 domains or advertiser IDs).

**Step 2: For each competitor**, run a listing search and collect:
- Total ad count
- Format breakdown (text/image/video)
- Active vs historical ads
- Platform distribution
- Key messaging themes (from headlines/snippets of top creatives)

**Step 3: Compare across dimensions:**

```
📊 Competitive Ad Comparison

| Metric | [Brand A] | [Brand B] | [Brand C] |
|--------|-----------|-----------|-----------|
| Total ads | X | Y | Z |
| Text ads | X | Y | Z |
| Image ads | X | Y | Z |
| Video ads | X | Y | Z |
| Active (last 30d) | X | Y | Z |
| Primary platform | Search | YouTube | Shopping |
| Top CTA | "Shop Now" | "Learn More" | "Get Started" |

Key Differences:
- [Brand A] focuses heavily on text ads with aggressive CTAs
- [Brand B] invests in video content on YouTube
- [Brand C] leads with Shopping/product ads
```

### 6. Political Ad Monitoring

Track political advertising in a specific region.

**Important:** Political ads require `political_ads=true` AND a `region` parameter. Without both, political ads won't appear.

**Step 1: Search for political ads.**
Use `google_ads_transparency_center` with `political_ads=true` and `region` set to the target region code. Optionally add `text` to search for a specific candidate, party, or PAC.

**Step 2: Analyze the results.**
Political ad details include `ad_funded_by` — the entity paying for the ad.

**What to track:**
- Which entities are advertising
- Volume of ads per entity
- Regional targeting patterns
- Format preferences (text vs video for different messages)
- Funding sources (`ad_funded_by`)
- Time patterns around elections/events

### 7. Ad Format Analysis

Research creative format trends for an industry or advertiser.

**Step 1: Get ad listings** with `creative_format` filter to isolate a specific format.

**Step 2: For each format, analyze patterns:**

**Text ads:**
- Average headline length
- Common power words and phrases
- CTA language patterns
- Sitelink topics and count
- Use of extensions

**Image ads:**
- Common dimensions (indicates platform targeting)
- Carousel vs single image ratio
- Visual style patterns (photography vs illustration vs design)
- CTA overlay patterns

**Video ads:**
- Duration distribution
- YouTube vs non-YouTube hosting
- Whether ads are repurposed content or ad-specific

### 8. Regional Ad Research

Understand how an advertiser targets different geographic markets.

**Step 1: Run listing search** for the advertiser.

**Step 2: Fetch details on key creatives** — the `regions[]` array in details shows every region where that ad ran, with timing data.

**Step 3: Map regional strategy:**
- Which regions get the most ads?
- Do they localize creatives or use the same ads globally?
- Regional launch timing — staggered rollout or simultaneous?
- Which regions see the ad most (`times_shown`)?

**Use `region` filter** on the listing search to see only ads shown in a specific region.

## Common Patterns

### "What ads is [company] running?"
1. Search with `text=[company domain]`
2. Present total count, format breakdown, and top 5-10 most recent creatives
3. Offer to drill into specific ads or filter by format/platform

### "Compare [brand A] vs [brand B] ads"
1. Search each brand separately
2. Build comparison table (counts, formats, platforms, themes)
3. Fetch details on 2-3 top creatives per brand for messaging comparison

### "Show me their YouTube ads"
1. Search with `text=[domain]` and `platform=YOUTUBE`
2. Fetch details on video creatives for duration, headline, CTA
3. Present with video durations and messaging summaries

### "What political ads are running in [region]?"
1. Search with `political_ads=true`, `region=[code]`
2. Group by `advertiser` / `ad_funded_by`
3. Present volume per entity with date ranges

### "How has [company]'s advertising changed over the past year?"
1. Search with `text=[domain]`, `start_date` = 1 year ago, `end_date` = today
2. Analyze `first_shown`/`last_shown` patterns
3. Break into quarterly or monthly clusters
4. Note format shifts, messaging changes, new campaigns

## Tips

- **Domain search is easiest** — use `text=domain.com` to find any advertiser. No need to know the advertiser ID upfront.
- **Multiple advertiser IDs** — `advertiser_id` accepts comma-separated IDs to search multiple advertisers at once.
- **Active vs historical** — Compare `last_shown` timestamps against today to determine which ads are currently active vs archived.
- **Date filtering for campaigns** — Use `start_date`/`end_date` to isolate specific campaign periods (product launches, holidays, events).
- **Political ads are separate** — They never appear in regular results. Always set `political_ads=true` to find them.
- **`num` for batch size** — Default is 40 results. Set `num=100` for larger batches (one credit per page regardless of size).
- **Creative screenshots** — The `image` field in listing results is a rendered screenshot of the ad. Useful for visual analysis even without fetching full details.
- **Timestamp conversion** — `first_shown` and `last_shown` are Unix timestamps. Convert with standard date functions for human-readable dates.
- **Region codes** — These are numeric codes used by Google's Ads Transparency Center. Common ones: `2840` (US), `2826` (UK), `2276` (Germany), `2250` (France). When unsure, omit region to search globally.
