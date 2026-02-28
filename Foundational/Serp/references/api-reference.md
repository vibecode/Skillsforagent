# SerpApi YouTube API Reference

Complete parameter and response reference for all YouTube engines.

## Table of Contents

- [Common Parameters](#common-parameters)
- [YouTube Search (engine=youtube)](#youtube-search)
- [YouTube Video (engine=youtube_video)](#youtube-video)
- [YouTube Video Transcript (engine=youtube_video_transcript)](#youtube-video-transcript)
- [Search Result Types](#search-result-types)
- [Pagination Patterns](#pagination-patterns)
- [Filter Codes (sp parameter)](#filter-codes)

---

## Common Parameters

These apply to **all** YouTube engines:

| Parameter | Required | Description |
|-----------|----------|-------------|
| `engine` | ✅ | Engine name (see per-engine sections) |
| `api_key` | ✅ | SerpApi private API key |
| `output` | ❌ | `json` (default) or `html` |
| `no_cache` | ❌ | `true` to bypass 1h cache (don't combine with `async`) |
| `async` | ❌ | `true` to submit and retrieve later via Searches Archive API (don't combine with `no_cache`) |
| `zero_trace` | ❌ | Enterprise only. `true` to skip storing search data on SerpApi servers |
| `json_restrictor` | ❌ | Restrict output fields for smaller responses |

---

## YouTube Search

**Engine:** `youtube`
**Endpoint:** `GET https://serpapi.com/search?engine=youtube`
**Docs:** https://serpapi.com/youtube-search-api

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `search_query` | ✅ | Search query (same as YouTube search bar) |
| `gl` | ❌ | Country code (e.g., `us`, `uk`, `fr`). See [Google countries](https://serpapi.com/google-countries) |
| `hl` | ❌ | Language code (e.g., `en`, `es`, `fr`). See [Google languages](https://serpapi.com/google-languages) |
| `sp` | ❌ | Pagination token or filter code (see [Filter Codes](#filter-codes)) |

### Response Fields

```
search_information.total_results        — Total result count
search_information.video_results_state  — e.g., "Results for exact spelling"

ads_results[]                — Sponsored video results
  .position_on_page, .title, .link, .serpapi_link
  .channel {.name, .link}
  .views, .description, .length
  .thumbnail {.static, .rich}

movie_results[]              — Movie/purchasable results
  .position_on_page, .title, .link, .serpapi_link
  .channel {.name, .link, .verified}
  .length, .description, .info[], .extensions[]
  .thumbnail (string URL)

video_results[]              — Main organic video results
  .position_on_page, .title, .link, .serpapi_link
  .channel {.name, .link, .verified, .thumbnail}
  .published_date, .views, .length, .description
  .extensions[] (e.g., "New", "4K", "CC", "LIVE")
  .live (boolean), .watching (int, for live streams)
  .thumbnail {.static, .rich}

playlist_results[]           — Playlist results
  .position_on_page, .title, .link
  .video_count, .videos[]

channel_results[]            — Channel results
  .position_on_page, .title, .link, .verified
  .handle, .subscribers, .description, .thumbnail

shorts_results[]             — YouTube Shorts sections
  .position_on_page
  .shorts[] {.title, .link, .thumbnail, .views_original, .views, .video_id}

<category_name>[]            — Category results (e.g., "top_news", "latest_from_...")
  Same fields as video_results

searches_related_to_<query>  — Related searches
  .position_on_page
  .searches[] {.query, .link, .thumbnail}

people_also_search_for       — People also search for
  .position_on_page
  .searches[] {.query, .link, .thumbnail}

serpapi_pagination.next_page_token  — Token for next page (pass as `sp`)
```

### Example Request

```
GET https://serpapi.com/search?engine=youtube&search_query=coffee&api_key=KEY
```

---

## YouTube Video

**Engine:** `youtube_video`
**Endpoint:** `GET https://serpapi.com/search?engine=youtube_video`
**Docs:** https://serpapi.com/youtube-video-api

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `v` | ✅* | Video ID (from `youtube.com/watch?v=ID` or `youtu.be/ID`) |
| `gl` | ❌ | Country code |
| `hl` | ❌ | Language code |
| `next_page_token` | ❌ | Pagination token for related videos, comments, or replies |

*Required for initial request. When paginating with `next_page_token`, `v` is embedded in the token.

### Response Fields

```
title                        — Video title
thumbnail                    — Video thumbnail URL (maxresdefault)
channel                      — Channel info
  .name, .thumbnail, .link, .subscribers
views                        — Formatted views string
extracted_views              — Integer view count
likes                        — Formatted likes string
extracted_likes              — Integer like count
published_date               — Publication date string

description                  — Video description
  .content                   — Full text
  .links[]                   — Embedded links
    .start_index, .length, .text, .url

chapters[]                   — Video chapters
  .title, .thumbnail, .time_start (seconds)

related_videos[]             — Related/suggested videos
  .video_id, .link, .serpapi_link
  .thumbnail {.static, .rich}
  .title, .published_date, .views, .extracted_views, .length
  .channel {.name, .link, .thumbnail, .verified}

related_videos_next_page_token  — Token for next page of related videos

comments[]                   — Comments (may require next_page_token to load)
  .comment_id, .link
  .channel {.name, .link, .thumbnail, .verified}
  .published_date, .content
  .vote_count (string), .extracted_vote_count (int)
  .reply_count (int)
  .replies_next_page_token   — Token to fetch this comment's replies

comments_next_page_token     — Token for next page of comments

comments_sorting_token[]     — Comment sort options
  .title ("Top comments" | "Newest first")
  .token                     — Pass as next_page_token to sort

comment_parent_id            — Present when viewing replies
replies[]                    — Reply comments (same structure as comments[])
replies_next_page_token      — Token for next page of replies

transcript                   — Transcript availability
  .serpapi_link              — URL to fetch transcript via youtube_video_transcript engine
```

### Example: Get Video Details

```
GET https://serpapi.com/search?engine=youtube_video&v=dQw4w9WgXcQ&api_key=KEY
```

### Example: Get Comments (sorted newest first)

```
# 1. Get video → extract comments_sorting_token where title="Newest first"
# 2. Pass that token as next_page_token:
GET https://serpapi.com/search?engine=youtube_video&next_page_token=TOKEN&api_key=KEY
```

### Example: Get Comment Replies

```
# 1. Get comments → extract replies_next_page_token from a comment
# 2. Pass as next_page_token:
GET https://serpapi.com/search?engine=youtube_video&next_page_token=TOKEN&api_key=KEY
```

---

## YouTube Video Transcript

**Engine:** `youtube_video_transcript`
**Endpoint:** `GET https://serpapi.com/search?engine=youtube_video_transcript`
**Docs:** https://serpapi.com/youtube-video-transcript

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `v` | ✅ | Video ID |
| `language_code` | ❌ | Language code (default: `en`). Supports two-letter (`en`) or extended (`es-ES`, `zh-Hans`) codes. Falls back to first available if unavailable. |
| `title` | ❌ | Specific transcript title (e.g., `Twitch Chat - Simple`) |
| `type` | ❌ | Transcript type. E.g., `asr` for auto-generated speech recognition |

### Response Fields

```
transcript[]                 — Transcript segments
  .start_ms                  — Start time in milliseconds
  .end_ms                    — End time in milliseconds
  .snippet                   — Text content of the segment
  .start_time_text           — Formatted start time (e.g., "0:07")

chapters[]                   — Video chapters
  .chapter                   — Chapter title
  .start_ms, .end_ms         — Time range in milliseconds

available_transcripts[]      — All available transcript options
  .language_name             — Display name (e.g., "English")
  .language_code             — Code (e.g., "en")
  .type                      — Type (e.g., "asr")
  .title                     — Custom title (for community/chat transcripts)
  .selected                  — true if this is the current transcript
  .serpapi_link              — Direct URL to fetch this transcript
```

### Example Request

```
GET https://serpapi.com/search?engine=youtube_video_transcript&v=Gk8gB5VACZw&language_code=en&type=asr&api_key=KEY
```

---

## Search Result Types

These are sub-result types returned within the YouTube Search response. They don't have their own engines — they appear as arrays in the search response.

### Video Results
Docs: https://serpapi.com/youtube-video-results

Main organic results in `video_results[]`. Fields: `position_on_page`, `title`, `link`, `serpapi_link`, `channel`, `published_date`, `views`, `length`, `description`, `extensions[]`, `thumbnail`, `live`, `watching`.

A search without `search_query` is valid when using `sp` filters (e.g., live-only filter).

### Channel Results
Docs: https://serpapi.com/youtube-channel-results

Appear in `channel_results[]`. Fields: `position_on_page`, `title`, `link`, `verified`, `handle`, `subscribers`, `description`, `thumbnail`.

### Shorts Results
Docs: https://serpapi.com/youtube-shorts-results

Appear in `shorts_results[]`. Each entry has `position_on_page` and `shorts[]` array with: `title`, `link`, `thumbnail`, `views_original`, `views`, `video_id`.

### Category Results
Docs: https://serpapi.com/youtube-category-results

Categorized results appear as dynamic keys like `top_news`, `latest_from_star_wars`, `learn_while_you_re_at_home`, etc. Same structure as `video_results` items.

### Related Searches
Docs: https://serpapi.com/youtube-related_searches

Appear as `searches_related_to_<query>` or `people_also_search_for`. Each has `position_on_page` and `searches[]` with: `query`, `link`, `thumbnail`.

---

## Pagination Patterns

### Search Pagination
YouTube uses **token-based** continuous pagination (not page numbers).

```
# Initial search
GET /search?engine=youtube&search_query=coffee&api_key=KEY

# Next page — use serpapi_pagination.next_page_token as `sp`
GET /search?engine=youtube&search_query=coffee&sp=TOKEN&api_key=KEY
```

### Video Related Videos Pagination
```
# Initial video request returns related_videos + related_videos_next_page_token
GET /search?engine=youtube_video&v=VIDEO_ID&api_key=KEY

# Next page of related videos
GET /search?engine=youtube_video&next_page_token=TOKEN&api_key=KEY
```

### Comment Pagination
```
# Get initial comments from video response → comments_next_page_token
# Or sort comments → comments_sorting_token[].token
GET /search?engine=youtube_video&next_page_token=TOKEN&api_key=KEY

# Returns comments[] + comments_next_page_token for further pages
```

### Reply Pagination
```
# Get replies for a comment → use comment's replies_next_page_token
GET /search?engine=youtube_video&next_page_token=TOKEN&api_key=KEY

# Returns comment_parent_id, replies[], replies_next_page_token
```

---

## Filter Codes

The `sp` parameter for YouTube Search accepts filter codes. Common values:

| Filter | `sp` Value |
|--------|-----------|
| Upload date: Last hour | `EgIIAQ%3D%3D` |
| Upload date: Today | `EgIIAg%3D%3D` |
| Upload date: This week | `EgIIAw%3D%3D` |
| Upload date: This month | `EgIIBA%3D%3D` |
| Upload date: This year | `EgIIBQ%3D%3D` |
| Sort by: Upload date | `CAI%3D` |
| Type: Video | `EgIQAQ%3D%3D` |
| Type: Channel | `EgIQAg%3D%3D` |
| Type: Playlist | `EgIQAw%3D%3D` |
| Type: Movie | `EgIQBA%3D%3D` |
| Duration: Under 4 min | `EgIYAQ%3D%3D` |
| Duration: 4-20 min | `EgIYAw%3D%3D` |
| Duration: Over 20 min | `EgIYAg%3D%3D` |
| Features: Live | `EgJAAQ%3D%3D` |
| Features: 4K | `EgJwAQ%3D%3D` |
| Features: HD | `EgIgAQ%3D%3D` |
| Features: Subtitles/CC | `EgIoAQ%3D%3D` |
| Features: 360° | `EgJ4AQ%3D%3D` |
| Features: VR180 | `EgPQAQE%3D` |
| Exact spelling | `QgIIAQ%3D%3D` |

**Tip:** To get any custom filter, visit YouTube, apply filters, and copy the `sp` value from the URL.
