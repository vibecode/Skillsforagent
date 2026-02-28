---
name: serpapi-youtube
description: >
  Base skill for all SerpApi YouTube API interactions. Use when performing YouTube searches,
  fetching video details (metadata, comments, chapters), retrieving video transcripts,
  or browsing YouTube results via SerpApi. Covers all YouTube engines: youtube (search),
  youtube_video (video details + comments + related), and youtube_video_transcript (transcripts).
  Also handles search result types including video results, channel results, shorts results,
  category results, related searches, and playlist results. Use this skill whenever the task
  involves: (1) searching YouTube programmatically, (2) getting video metadata/details,
  (3) extracting video transcripts/captions, (4) fetching YouTube comments or replies,
  (5) browsing related videos or channels, (6) paginating YouTube results, (7) filtering
  YouTube searches by date/type/duration/features. This is the foundational SerpApi YouTube
  skill — specialized skills may extend it for specific workflows.
metadata: {"openclaw": {"emoji": "📺", "requires": {"env": ["SERPAPI_KEY"]}, "primaryEnv": "SERPAPI_KEY"}}
---

# SerpApi YouTube

Interact with YouTube via SerpApi's structured JSON API. Three engines cover all YouTube data needs.

## Setup

Requires `SERPAPI_KEY` environment variable. All requests go to `https://serpapi.com/search` as GET requests with `api_key` parameter.

## Engines Overview

| Engine | Purpose | Key Parameter |
|--------|---------|---------------|
| `youtube` | Search YouTube | `search_query` |
| `youtube_video` | Video details, comments, related | `v` (video ID) |
| `youtube_video_transcript` | Video transcripts/captions | `v` (video ID) |

## Quick Reference

### 1. Search YouTube

```bash
curl -s "https://serpapi.com/search?engine=youtube&search_query=QUERY&api_key=$SERPAPI_KEY"
```

**Parameters:** `search_query` (required), `gl` (country), `hl` (language), `sp` (filter/pagination token)

**Returns:** `video_results[]`, `channel_results[]`, `shorts_results[]`, `playlist_results[]`, `movie_results[]`, `ads_results[]`, category arrays, related searches, `serpapi_pagination.next_page_token`

### 2. Get Video Details

```bash
curl -s "https://serpapi.com/search?engine=youtube_video&v=VIDEO_ID&api_key=$SERPAPI_KEY"
```

**Parameters:** `v` (required), `gl`, `hl`, `next_page_token` (for comments/related pagination)

**Returns:** `title`, `channel`, `views`/`extracted_views`, `likes`/`extracted_likes`, `published_date`, `description`, `chapters[]`, `related_videos[]`, `comments[]`, pagination tokens, `transcript.serpapi_link`

### 3. Get Transcript

```bash
curl -s "https://serpapi.com/search?engine=youtube_video_transcript&v=VIDEO_ID&api_key=$SERPAPI_KEY"
```

**Parameters:** `v` (required), `language_code` (default: `en`), `title` (specific transcript name), `type` (`asr` for auto-generated)

**Returns:** `transcript[]` (with `start_ms`, `end_ms`, `snippet`, `start_time_text`), `chapters[]`, `available_transcripts[]`

## Pagination

All pagination is token-based. Never use page numbers.

- **Search pages:** Pass `serpapi_pagination.next_page_token` as `sp` to `youtube` engine
- **Related videos:** Pass `related_videos_next_page_token` as `next_page_token` to `youtube_video` engine
- **Comments:** Pass `comments_next_page_token` as `next_page_token` to `youtube_video` engine
- **Comment sorting:** Use `comments_sorting_token[].token` (options: "Top comments", "Newest first") as `next_page_token`
- **Replies:** Pass a comment's `replies_next_page_token` as `next_page_token` to `youtube_video` engine

## Search Filters

Pass filter codes via `sp` parameter. Common filters:

- **Sort by upload date:** `sp=CAI%3D`
- **Today only:** `sp=EgIIAg%3D%3D`
- **This week:** `sp=EgIIAw%3D%3D`
- **This month:** `sp=EgIIBA%3D%3D`
- **Videos only:** `sp=EgIQAQ%3D%3D`
- **Channels only:** `sp=EgIQAg%3D%3D`
- **Playlists only:** `sp=EgIQAw%3D%3D`
- **Live now:** `sp=EgJAAQ%3D%3D`
- **4K:** `sp=EgJwAQ%3D%3D`
- **HD:** `sp=EgIgAQ%3D%3D`
- **Has subtitles:** `sp=EgIoAQ%3D%3D`
- **Under 4 min:** `sp=EgIYAQ%3D%3D`
- **4-20 min:** `sp=EgIYAw%3D%3D`
- **Over 20 min:** `sp=EgIYAg%3D%3D`
- **Force exact spelling:** `sp=QgIIAQ%3D%3D`

Custom filters: visit YouTube, apply desired filters, copy `sp` from URL.

## Response Result Types

YouTube Search returns multiple result arrays depending on content:

| Array Key | Content |
|-----------|---------|
| `video_results[]` | Main organic video results |
| `channel_results[]` | Channel matches (with handle, subscribers, verified status) |
| `shorts_results[]` | Shorts sections (nested `.shorts[]` array with video_id, views) |
| `playlist_results[]` | Playlist matches |
| `movie_results[]` | Purchasable movie results |
| `ads_results[]` | Sponsored/ad results |
| `<category>[]` | Dynamic category groups (e.g., `top_news`, `latest_from_...`) |
| `searches_related_to_<query>` | Related search suggestions |
| `people_also_search_for` | PASF suggestions |

## Common Patterns

### Extract Video ID

From URL: `youtube.com/watch?v=VIDEO_ID` or `youtu.be/VIDEO_ID`
From search results: use `.link` and parse, or use video results' `serpapi_link` directly.

### Get All Comments for a Video

1. Fetch video: `engine=youtube_video&v=ID` → get `comments_sorting_token`
2. Optionally sort: pass "Newest first" token as `next_page_token`
3. Loop: collect `comments[]`, use `comments_next_page_token` for next page until no token returned

### Get Full Transcript as Text

1. Fetch transcript: `engine=youtube_video_transcript&v=ID&language_code=en`
2. Concatenate all `transcript[].snippet` values
3. Use `chapters[]` for section boundaries if needed

### Check Available Languages

The `available_transcripts[]` array lists every language/type option with `serpapi_link` for direct access.

## Detailed Reference

For complete parameter tables, response schemas, and JSON examples: read [references/api-reference.md](references/api-reference.md).

## Error Handling

- Check `search_metadata.status` — should be `"Success"`
- On error, `error` field contains the message
- Cache is 1h; use `no_cache=true` to force fresh results (costs a search credit)
- Don't combine `no_cache` and `async`
- Rate limits depend on your SerpApi plan
