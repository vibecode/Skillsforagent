---
name: serp-google-videos
display_name: Google Videos
description: >
  Specialized skill for Google Videos workflows via SerpApi — cross-platform video discovery,
  short-form content search, duration and date filtering, source platform diversity, and
  trend/news clip research. Covers both the `google_videos` engine (long-form across YouTube,
  Vimeo, TikTok, Facebook, Dailymotion, news sites, etc.) and the `google_short_videos` engine
  (short-form / Shorts / TikTok-style content). Use when: (1) searching for videos across
  multiple platforms in one query, (2) finding short-form / Shorts / TikTok content via
  google_short_videos, (3) filtering videos by duration (short / medium / long),
  (4) filtering videos by upload date (past hour / day / week / month / year),
  (5) restricting to HD or high-quality videos, (6) discovering news or event clips across
  multiple sources, (7) comparing video coverage from different platforms (YouTube vs Vimeo
  vs TikTok vs news outlets), (8) sampling source diversity for content research,
  (9) finding video clips with key moments / chapters, (10) any task requiring multi-platform
  video discovery rather than YouTube-only deep dives. For YouTube-only search, video details,
  comments, or transcripts use the dedicated `serpapi-youtube` skill instead. This skill
  builds on the foundational serpapi skill for all API details.
dependencies:
  - serpapi
metadata: {"openclaw": {"emoji": "🎥"}}
---

# Google Videos Workflows

Cross-platform video discovery, short-form content search, and source-diverse video research via SerpApi's Google Videos and Google Short Videos engines. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engines: `google_videos`, `google_short_videos`, optionally `google_videos_light`)

## Choosing the Right Engine

| Engine | When to Use |
|--------|-------------|
| `google_videos` | Default. Long-form and mixed video search across YouTube, Vimeo, TikTok, Facebook, Dailymotion, news sites, and more. Returns rich metadata (key moments, snippets, channels). |
| `google_short_videos` | Short-form discovery. Returns Shorts, TikTok-style clips, and Reels-format content aggregated across platforms. Use when the user wants Shorts, Reels, TikToks, or short-form trends. |
| `google_videos_light` | Speed-optimized variant of `google_videos`. Same core fields (title, link, thumbnail, duration, date, snippet) but omits rich elements like key moments. Use for high-volume scans where speed matters more than richness. |
| `youtube` (separate skill) | YouTube-only deep workflows: video search ranked by YouTube's own algorithm, video details, comments, transcripts, channel pages. See the **serpapi-youtube** skill. |

**Rule of thumb:** Use `google_videos` for cross-platform discovery; use `youtube` (separate skill) when the user explicitly wants YouTube or needs YouTube-specific metadata (views, likes, comments, transcripts).

## Core Concepts

### Cross-Platform Aggregation

Unlike the YouTube engine, `google_videos` aggregates results from many sources. A single search may return videos from:

- **YouTube** — Most common; full long-form and Shorts
- **Vimeo** — Creative, professional, indie content
- **TikTok** — Short-form viral clips
- **Facebook / Instagram** — Social platform videos and Reels
- **Dailymotion** — European long-form
- **News outlets** — CNN, BBC, Reuters, NYT, etc. embed video coverage
- **Educational** — Khan Academy, Coursera, TED
- **Brand / company sites** — Marketing and product videos

Each result's `source` (and `displayed_link`) identifies the platform. Use this for source-diverse content research.

### Response Structure — google_videos

The `video_results[]` array contains per-result fields:

- `position` — Ranking
- `title` — Video title
- `link` — Direct URL to the video
- `displayed_link` — Formatted source display (e.g., `www.youtube.com › watch`)
- `thumbnail` — Preview image URL
- `date` — Upload date (string, e.g., `"3 weeks ago"` or `"Mar 14, 2026"`)
- `snippet` — Text description
- `duration` — Length string (e.g., `"4:32"` or `"1:12:05"`)
- `key_moments[]` — Chapters with `time`, `title`, and `thumbnail` (when present)
- `rich_snippet` — Structured metadata (e.g., channel, creator, publish date)
- `video_link` — Inline preview clip URL (when present)

Additional top-level fields commonly returned:
- `filters[]` — Available refinement options (duration, date, source, etc.) as Google offers them
- `related_searches[]` — Suggested query variations
- `serpapi_pagination` — `next`, `previous`, and `other_pages` links

### Response Structure — google_short_videos

The `short_video_results[]` array contains:

- `position` — Ranking
- `title` — Video title
- `link` — Destination URL
- `thumbnail` — Preview image URL
- `clip` — Reference to a preview clip
- `source` — Platform name (YouTube, TikTok, Facebook, Instagram, etc.)
- `source_icon` — Platform logo URL
- `channel` — Creator / channel name
- `duration` — Length in `MM:SS` (short-form is typically under 60 seconds)

Top-level fields:
- `people_also_search_for` — Suggested related queries (tablet / mobile only)
- `serpapi_pagination` — Navigation links

### Pagination

Both engines paginate via the `start` parameter (result offset). Increment by the page size returned (commonly 10) to step through pages. Prefer following `serpapi_pagination.next` rather than computing offsets manually.

### tbs Filters

The `tbs` parameter encodes Google's advanced video filters (duration, upload date, quality, source). SerpApi forwards `tbs` to Google as-is. The exact codes are Google-side and can change.

**Practical strategy:**
1. Run an initial search without `tbs`. Inspect the returned `filters[]` array — Google often surfaces the exact filter strings it supports for that query.
2. Use those filter strings as `tbs` values for follow-up searches.
3. Common categories Google offers in video search: **Duration** (short < ~4 min, medium 4–20 min, long > ~20 min), **Upload date** (past hour, day, week, month, year), **Quality** (HD), **Source** (specific platform).

When the user asks for a specific filter, prefer this filters-introspection approach over hardcoding tbs codes that may drift.

### Localization

- `gl` — Two-letter country code (e.g., `us`, `gb`, `de`, `jp`)
- `hl` — Two-letter language code (e.g., `en`, `es`, `fr`)
- `location` — City-level origin (e.g., `"Austin, Texas, United States"`) — improves geo-relevance
- `lr` — Restrict to one or more languages, format `lang_en|lang_es`
- `google_domain` — e.g., `google.co.uk`, `google.de`

Localization significantly affects which platforms and creators rank — a query in `gl=de` may surface more Dailymotion / European sources; `gl=jp` surfaces more Niconico / Japanese platforms.

## Workflows

### 1. Basic Video Search

Use the **serpapi** skill's wrapper script with the `google_videos` engine.

**Required:** `q`
**Common optional:** `gl`, `hl`, `location`, `start`, `safe`

**Presentation pattern:** Show top 5–10 results with title, source platform, channel, duration, date, and link. Surface the thumbnail when the host UI supports inline images.

### 2. Short-Form Content Discovery

Use the `google_short_videos` engine for Shorts, Reels, and TikTok-style content.

**Required:** `q`
**Common optional:** same localization params as `google_videos`

**When to use:**
- User explicitly mentions Shorts, Reels, TikToks
- Looking for trending short clips on a topic
- Comparing short-form coverage to long-form (run both engines in parallel and contrast)

**Presentation pattern:** Lead with `source` platform per result so the user sees the platform mix (e.g., "5 TikTok, 3 YouTube Shorts, 2 Instagram Reels").

### 3. Duration Filtering

Goal: limit results to short (<~4 min), medium (4–20 min), or long (>~20 min) videos.

**Approach:**
1. Run an initial `google_videos` search.
2. Inspect the `filters[]` block for a `Duration` group; copy the desired option's `tbs` value.
3. Re-run with that `tbs` value.

**Heuristic fallback:** If a quick filter is needed, post-filter `video_results[]` by parsing the `duration` field (`"M:SS"` or `"H:MM:SS"`).

### 4. Date Filtering (Recent / News Clips)

Goal: surface recently uploaded videos — useful for news, events, trends.

**Approach:**
1. Initial search → read `filters[]` for the `Upload date` group (past hour / day / week / month / year).
2. Apply the desired `tbs` value.

**Heuristic fallback:** Post-filter by the `date` field (e.g., `"2 hours ago"`, `"3 days ago"`) — note these are relative strings, not absolute timestamps.

**Use cases:**
- Breaking news clips: filter to past hour or past day
- Event recaps: past week
- Trending topics: past week or past month

### 5. Source Platform Filtering

Goal: restrict to a specific platform (e.g., only Vimeo, only TikTok) or exclude one.

**Two approaches:**

**a) Query operator:**
- Include only: append `site:vimeo.com` (or `site:tiktok.com`, `site:dailymotion.com`) to `q`
- Exclude: append `-site:youtube.com` to `q`

**b) Filters introspection:**
- Inspect `filters[]` — Google sometimes offers source filters as `tbs` codes for a given query.

The query operator approach is more reliable across queries.

### 6. Cross-Platform Source Diversity

Goal: see how a topic is covered across platforms in a single sweep.

**Strategy:**
1. Run one `google_videos` search.
2. Group `video_results[]` by `source` / `displayed_link` host.
3. Present a platform breakdown table:

```
| Platform     | Count | Sample Title                                  |
|--------------|-------|-----------------------------------------------|
| YouTube      | 6     | "How the New M5 Pro Works"                    |
| Vimeo        | 2     | "M5 Pro — Director's Cut"                     |
| TikTok       | 1     | "M5 Pro reaction in 30 seconds"               |
| The Verge    | 1     | "First look: M5 Pro hands-on"                 |
```

**Use cases:** Content research, competitive landscape, gauging where conversation is happening.

### 7. HD / Quality Filtering

Inspect the initial response's `filters[]` for a quality option (typically "HD"). Apply the surfaced `tbs` value. There is no reliable post-filter field on each result — rely on Google's filter for this.

### 8. News & Event Clip Discovery

Combine date filter + source diversity for current-event coverage.

**Pattern:**
1. Search `q` with date filter set to past day or past week (via `tbs` from `filters[]`).
2. Group by `source` to see which outlets are covering the story.
3. Sample one clip per major platform / outlet.

**Why this beats Google News:** Google Videos surfaces broadcast clips, social reactions, creator commentary, and official statements in one list — much richer than text-only news.

### 9. Trend / Viral Short-Form Sweep

Use `google_short_videos` for tracking short-form virality.

**Pattern:**
1. Search the trend term on `google_short_videos`.
2. Bucket by `source` (TikTok vs YouTube Shorts vs Reels).
3. Note `channel` repetition — recurring channels indicate creator-driven trends; many one-off channels indicate organic virality.

### 10. Key Moments / Chapter Extraction

For long-form videos, `key_moments[]` (when present) gives jumpable chapters with timestamps and thumbnails.

**Use cases:**
- Recommend specific timestamps for a long tutorial
- Surface the relevant chapter for a question (e.g., "where in this 2-hour video does it cover X?")
- Build chapter summaries

### 11. Speed-Optimized Bulk Discovery

For high-volume scans where you need many queries fast and don't need `key_moments` or rich snippets, swap `engine` to `google_videos_light`. Same core fields, faster response, lower payload.

## Filter Quick Reference

| Goal | Approach |
|------|----------|
| Recent clips (past day/week) | Inspect `filters[]` → apply Upload-date `tbs` value |
| Short / medium / long duration | Inspect `filters[]` → apply Duration `tbs` value; or post-filter `duration` field |
| HD only | Inspect `filters[]` → apply Quality `tbs` value |
| Only YouTube | Append `site:youtube.com` to `q` |
| Only Vimeo | Append `site:vimeo.com` to `q` |
| Only TikTok | Append `site:tiktok.com` to `q` |
| Exclude a platform | Append `-site:<platform>.com` to `q` |
| Shorts / Reels / TikToks | Switch to `engine=google_short_videos` |
| Localized results | Set `gl`, `hl`, `location`, optionally `google_domain` |
| Faster, lighter payload | Switch to `engine=google_videos_light` |
| Mobile-formatted results | Set `device=mobile` |
| Safe search | Set `safe=active` |

## Presenting Results

### Video Result Format

For each result, present:

```
🎥 [Title] — [Duration]
   📺 [Source platform] · [Channel] · [Date]
   [Snippet — 1 line]
   🔗 [link]
```

When thumbnails render inline in the host UI, show the `thumbnail` URL above the title.

### Platform Breakdown Summary

When source diversity is the point of the answer, lead with the breakdown:

```
🎥 [Query] — Cross-Platform Coverage

📊 Source Mix (top 10 results):
   YouTube  ████████ 6
   Vimeo    ██       2
   TikTok   █        1
   The Verge █       1

🌟 Highlights:
   • YouTube — "[best YouTube title]" ([channel], [duration])
   • Vimeo — "[best Vimeo title]" ([channel], [duration])
   • TikTok — "[best TikTok title]" ([channel], [duration])
```

### Short-Form Sweep Format

```
🎬 Short-Form: [Query]

📊 Platform Mix: TikTok (5), YT Shorts (3), Reels (2)

🔥 Top Clips:
   1. [Title] · TikTok · @[channel] · 0:28
   2. [Title] · YouTube Shorts · @[channel] · 0:45
   ...
```

## Common Patterns

### "Find videos about [topic]"
1. `google_videos` search with `q=[topic]`
2. Present top 5–10 with title, source, channel, duration, date, link
3. Note the platform mix

### "Find short videos / Shorts / TikToks about [topic]"
1. `google_short_videos` search
2. Group by `source`; present platform mix + top clips

### "What are people saying about [event] in videos right now?"
1. `google_videos` initial search → grab Upload-date `tbs` from `filters[]` (past day or past hour)
2. Re-run with that `tbs`
3. Group by `source` to show which outlets / creators are covering it

### "Find the best HD tutorial on [topic]"
1. Initial `google_videos` search → grab Quality `tbs` (HD) from `filters[]` and a long-duration `tbs` if available
2. Re-run with both filters merged
3. Present results favoring established educational channels (visible in `channel` / `source`)

### "Where in this long video does it cover [subtopic]?"
1. `google_videos` search targeting the video
2. Read `key_moments[]` on the matching result
3. Point to the timestamped chapter

### "Compare how YouTube vs TikTok covers [topic]"
1. Run `google_videos` with `site:youtube.com` appended
2. Run `google_short_videos` (or `google_videos` with `site:tiktok.com`) in parallel
3. Contrast tone, format, top creators

### "I want a Vimeo-only creative reference for [theme]"
1. `google_videos` with `q="[theme] site:vimeo.com"`
2. Present results emphasizing creator (channel) and duration

## Tips

- **Don't conflate with the YouTube engine.** For YouTube-specific workflows (views, likes, comments, transcripts, channel pages), redirect to the **serpapi-youtube** skill. Use `google_videos` only when cross-platform discovery is the goal.
- **Inspect `filters[]` before hardcoding tbs.** Google updates filter codes; the `filters[]` block in any initial response gives you the exact, current `tbs` strings to reuse.
- **`site:` operators are reliable.** When platform restriction matters, prefer `q` with `site:` over guessing tbs source codes.
- **`date` is a relative string.** `"3 weeks ago"` is not parseable as an absolute timestamp. For absolute date sorting, rely on `tbs` upload-date filters.
- **`duration` parses as MM:SS or H:MM:SS.** Use this for post-filtering when you can't or don't want to round-trip through `filters[]`.
- **`google_short_videos` is platform-agnostic.** Don't assume "shorts" means YouTube Shorts — results include TikTok, Reels, Facebook short videos, and more. Always show `source` per result.
- **Localization changes source mix.** `gl=de` surfaces more Dailymotion; `gl=jp` surfaces more Niconico; `gl=cn`-adjacent surfaces more Bilibili-style platforms (when reachable). Set `gl`/`hl` thoughtfully for international research.
- **`key_moments` is a high-value field.** When present, it lets you point users to exact timestamps inside long videos — much more useful than just linking the video.
- **`google_videos_light` for bulk runs.** If you're running 20+ queries to build a dataset, the light engine cuts payload size and latency without losing core fields.
- **Pagination via `serpapi_pagination.next`.** Follow the returned link rather than computing `start` offsets — it's more robust.
- **`safe=active`** filters adult content; default is unset. Apply it for family / education contexts.
- **`device=mobile`** changes the result layout slightly and may surface `people_also_search_for` in `google_short_videos`. Use when emulating mobile users.
